pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = 'your-dockerhub-username' // change as your username
        IMAGE_REPO         = 'vue-nodejs-youtube-clone'
        IMAGE_NAME         = "${DOCKERHUB_USERNAME}/${IMAGE_REPO}"
        IMAGE_TAG          = "${env.BUILD_NUMBER}"
        DOCKERHUB_CREDS    = 'dockerhub-credentials'
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    triggers {
        githubPush()
        pollSCM('H/3 * * * *')
    }

    stages {
        stage('Build Docker Image') {
            steps {
                echo "Building image ${IMAGE_NAME}:${IMAGE_TAG} (multi-stage build inside Docker)..."
                sh '''
                    docker build \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${IMAGE_NAME}:latest \
                        -f Dockerfile .
                    docker images | grep ${IMAGE_REPO} || true
                '''
            }
        }

        stage('Login to Docker Hub') {
            steps {
                echo 'Logging in to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDS}",
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_PASS'
                )]) {
                    sh '''
                        echo "${DH_PASS}" | docker login -u "${DH_USER}" --password-stdin
                    '''
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "Pushing ${IMAGE_NAME}:${IMAGE_TAG} and :latest ..."
                sh '''
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${IMAGE_NAME}:latest
                '''
            }
        }
    }

    post {
        always {
            echo 'Cleaning up local Docker images & logging out...'
            sh '''
                docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                docker rmi ${IMAGE_NAME}:latest || true
                docker logout || true
            '''
        }
        success {
            echo "Pipeline succeeded. Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
