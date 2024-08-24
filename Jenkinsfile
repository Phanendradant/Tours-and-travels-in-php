
pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
    }
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t tours-travels-app .'
            }
        }
        stage('Push to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.${AWS_REGION}.amazonaws.com
                docker tag tours-travels-app:latest <aws_account_id>.dkr.ecr.${AWS_REGION}.amazonaws.com/tours-travels-app:latest
                docker push <aws_account_id>.dkr.ecr.${AWS_REGION}.amazonaws.com/tours-travels-app:latest
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

