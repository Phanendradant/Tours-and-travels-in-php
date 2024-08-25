pipeline {
    agent any // This allows Jenkins to use any available agent
    environment {
        AWS_REGION = 'us-west-2'
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Phanendradant/Tours-and-travels-in-php.git'
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
                sh 'docker build -t tours-travels-app .'
            }
        }
        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin 605134427539.dkr.ecr.us-west-2.amazonaws.com
                    docker tag tours-travels-app:latest 605134427539.dkr.ecr.us-west-2.amazonaws.com/tours-travels-app:latest
                    docker push 605134427539.dkr.ecr.us-west-2.amazonaws.com/tours-travels-app:latest
                    '''
                }
            }
        }
        stage('Deploy to EKS') {
            
