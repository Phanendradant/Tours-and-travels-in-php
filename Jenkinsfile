pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
        REPO_URL = 'https://github.com/Phanendradant/Tours-and-travels-in-php.git'
        DOCKER_IMAGE_NAME = 'tours-travels-app'
        ECR_REPOSITORY = '605134427539.dkr.ecr.us-west-2.amazonaws.com/tours-travels-app'
        KUBECONFIG_PATH = '/path/to/your/kubeconfig'
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: "${REPO_URL}"
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'composer install'
            }
        }
        stage('Run Unit Tests') {
            steps {
                sh 'phpunit --configuration phpunit.xml'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE_NAME} ."
            }
        }
        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}
                    docker tag ${DOCKER_IMAGE_NAME}:latest ${ECR_REPOSITORY}:latest
                    docker push ${ECR_REPOSITORY}:latest
                    '''
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh '''
                export KUBECONFIG=${KUBECONFIG_PATH}
                kubectl config view
                helm upgrade --install ${DOCKER_IMAGE_NAME} ./mychart --set image.tag=latest
                '''
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Please check the logs.'
        }
    }
}
