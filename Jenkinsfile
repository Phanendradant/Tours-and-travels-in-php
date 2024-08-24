
pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
    }
    stages {
        stage('Build') {
            steps {
                sh 'sudo usermod -aG docker $USER'
                sh 'newgrp docker'
                sh 'newgrp docker'
                sh 'docker build -t tours-travels-app .'
            }
        }
        stage('Push to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 867344437404.dkr.ecr.us-west-2.amazonaws.com
                docker build -t tours-and-travels-in-php .
                docker tag tours-and-travels-in-php:latest 867344437404.dkr.ecr.us-west-2.amazonaws.com/tours-and-travels-in-php:latest
                docker push 867344437404.dkr.ecr.us-west-2.amazonaws.com/tours-and-travels-in-php:latest
                '''
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh 'helm upgrade --install tours-travels-app ./mychart --set image.tag=latest'
            }
        }
    }
}

