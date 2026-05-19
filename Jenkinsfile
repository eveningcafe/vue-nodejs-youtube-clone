pipeline {
    agent any

    environment {
        AWS_REGION       = 'ap-southeast-1'
        AWS_ACCOUNT_ID   = '891920435433' // change as your account
        ECR_REPO_NAME    = 'vue-nodejs-youtube-clone'
        ECR_REGISTRY     = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_NAME       = "${ECR_REGISTRY}/${ECR_REPO_NAME}"
        IMAGE_TAG        = "${env.BUILD_NUMBER}"
        AWS_CREDENTIALS  = 'aws-ecr-credentials'
        NODE_VERSION     = '16'
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Setup Node & Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies...'
                sh '''
                    node -v
                    npm -v
                    npm ci --no-audit --no-fund
                '''
            }
        }

        stage('Lint') {
            steps {
                echo 'Running lint...'
                sh 'npm run lint || true'
            }
        }

        stage('Build Dist') {
            steps {
                echo 'Building Vue app -> dist/ ...'
                sh 'npm run build'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'dist/**', fingerprint: true, onlyIfSuccessful: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG} ..."
                sh '''
                    docker build \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${IMAGE_NAME}:latest \
                        -f Dockerfile .
                    docker images | grep ${ECR_REPO_NAME} || true
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                echo 'Logging in to AWS ECR...'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        aws ecr describe-repositories \
                            --repository-names ${ECR_REPO_NAME} \
                            --region ${AWS_REGION} >/dev/null 2>&1 || \
                        aws ecr create-repository \
                            --repository-name ${ECR_REPO_NAME} \
                            --region ${AWS_REGION}

                        aws ecr get-login-password --region ${AWS_REGION} \
                            | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                echo "Pushing image to ${ECR_REGISTRY} ..."
                sh '''
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${IMAGE_NAME}:latest
                '''
            }
        }
    }

    post {
        always {
            echo 'Cleaning up local Docker images...'
            sh '''
                docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                docker rmi ${IMAGE_NAME}:latest || true
                docker logout ${ECR_REGISTRY} || true
            '''
        }
        success {
            echo "Pipeline succeeded. Image: ${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
