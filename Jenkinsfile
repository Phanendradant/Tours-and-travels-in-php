pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
        KUBECONFIG = '/var/lib/jenkins/.kube/config' // Updated path to the kubeconfig
    }
    stages {
        stage('Setup Environment') {
            steps {
                script {
                    // Ensure Jenkins user is part of the Docker group
                    sh 'sudo usermod -aG docker jenkins || true'
                    sh 'sudo systemctl restart docker || true'
                }
            }
        }
        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/Phanendradant/Tours-and-travels-in-php.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t tours-and-travels-in-php .'
            }
        }
        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin 605134427539.dkr.ecr.us-west-2.amazonaws.com
                    docker tag tours-and-travels-in-php:latest 605134427539.dkr.ecr.us-west-2.amazonaws.com/tours-and-travels-in-php:latest
                    docker push 605134427539.dkr.ecr.us-west-2.amazonaws.com/tours-and-travels-in-php:latest
                    '''
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                script {
                    sh '''
                    export KUBECONFIG=${KUBECONFIG}
                    kubectl config view
                    kubectl get nodes
                    helm upgrade --install tours-travels-app ./mychart --set image.tag=latest
                    '''
                }
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
