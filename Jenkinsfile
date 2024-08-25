pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
    }
    stages {
        stage('Setup Environment') {
            steps {
                sh '''
                sudo apt-get update
                sudo apt-get install -y awscli
                sudo usermod -aG docker jenkins
                newgrp docker
                '''
            }
        }
        stage('Build') {
            steps {
                sh 'docker build -t tours-travels-app .'
            }
        }
        stage('Push to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 605134427539.dkr.ecr.us-west-2.amazonaws.com
                    docker build -t tours-and-travels-in-php .
                    docker tag tours-and-travels-in-php:latest 605134427539.dkr.ecr.us-west-2.amazonaws.com/tours-and-travels-in-php:latest
                    docker push 605134427539.dkr.ecr.us-west-2.amazonaws.com/tours-and-travels-in-php:latest
                    '''
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh '''
                export KUBECONFIG=/path/to/your/kubeconfig
                kubectl config view
                helm upgrade --install tours-travels-app ./mychart --set image.tag=latest
                '''
            }
        }
    }
}
