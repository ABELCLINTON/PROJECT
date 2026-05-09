pipeline {
    agent any
    tools {
        maven 'maven-3'
    }
    environment {
        MAVEN_OPTS     = "-Dmaven.repo.local=/var/lib/jenkins/.m2/repository"
        AWS_REGION     = 'us-east-1'
        AWS_ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
        ECR_REPO       = 'your-ecr-repo-name'   // just hardcode repo name, it's not sensitive
        IMAGE_TAG      = "${BUILD_NUMBER}"
        TF_DIR         = '.'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build with Maven') {
            steps {
                sh 'mvn install -DskipTests'
            }
        }
        stage('Run Tests') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                '''
            }
        }
        stage('Terraform Apply - ECR Only') {
            steps {
                dir("${env.TF_DIR}") {
                   sh """
                     terraform apply -auto-approve \
                     -target=module.ec2.aws_ecr_repository.app \
                     -var "image_tag=${BUILD_NUMBER}"
                   """
                }
            }
        }
        stage('Build & Push to ECR') {
            steps {
                sh """
                  aws ecr get-login-password --region ${AWS_REGION} | \
                  docker login --username AWS --password-stdin \
                  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                  docker tag ${ECR_REPO}:${IMAGE_TAG} \
                  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

                  docker push \
                  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }
        stage('Terraform Init') {
            steps {
                dir("${env.TF_DIR}") {
                    sh 'terraform init -input=false'
                }
            }
        }
        stage('Terraform Validate') {
            steps {
                dir("${env.TF_DIR}") {
                    sh 'terraform validate'
                }
            }
        }
        stage('Terraform Plan') {
            steps {
                dir("${env.TF_DIR}") {
                    sh """
                        terraform plan \
                        -var "aws_account_id=${AWS_ACCOUNT_ID}" \
                        -var "aws_region=${AWS_REGION}" \
                        -var "ecr_repo=${ECR_REPO}" \
                        -var "image_tag=${BUILD_NUMBER}" \
                        -var "environment=dev" \
                        -out=tfplan
                    """
                }
            }
        }
        stage('Terraform Apply - Full Deploy') {
            steps {
                dir("${env.TF_DIR}") {
                   sh """
                      terraform apply -auto-approve \
                      -var "image_tag=${BUILD_NUMBER}"
                    """
                }
            }
        }
        stage('Post-Deploy Info') {
            steps {
                dir("${env.TF_DIR}") {
                    sh 'terraform output'
                }
            }
        }
    }
    post {
        success {
            echo '✅ Build & Deploy completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs above.'
        }
    }
}
