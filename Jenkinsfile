pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')  // Replace with your Jenkins credentials ID
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')  // Replace with your Jenkins credentials ID
    }
    stages {
        stage('Setup Environment') {
            steps {
                sh '''
                sudo apt-get update
                sudo apt-get install -y awscli
                '''
            }
        }
        stage('Build') {
            steps {
                sh 'sudo docker build -t tours-travels-app .'
            }
        }
        stage('Push to ECR') {
            steps {
                withEnv(["AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}", "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}"]) {
                    sh '''
                    aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin 867344437404.dkr.ecr.us-west-2.amazonaws.com
                    sudo docker build -t tours-and-travels-in-php .
                    sudo docker tag tours-and-travels-in-php:latest 867344437404.dkr.ecr.us-west-2.amazonaws.com/tours-and-travels-in-php:latest
                    sudo docker push 867344437404.dkr.ecr.us-west-2.amazonaws.com/tours-and-travels-in-php:latest
                    '''
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh 'helm upgrade --install tours-travels-app ./mychart --set image.tag=latest'
            }
        }
    }
}
