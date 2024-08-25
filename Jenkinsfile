pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
    }
    stages {
        stage('Checkout Code') {
            steps {
                // Checkout the latest code from your Git repository
                git branch: 'master', url: 'https://github.com/Phanendradant/Tours-and-travels-in-php.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                // Build the Docker image using the Dockerfile
                sh 'docker build -t tours-travels-app .'
            }
        }
        stage('Run Unit Tests') {
            steps {
                // Run the unit tests inside the Docker container
                sh 'docker run --rm tours-travels-app composer install'
                sh 'docker run --rm tours-travels-app phpunit --configuration phpunit.xml'
            }
        }
        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    // Tag and push the Docker image to Amazon ECR
                    sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin 605134427539.dkr.ecr.us-west-2.amazonaws.com
                    docker tag tours-travels-app:latest 605134427539.dkr.ecr.us-west-2.amazonaws.com/tours-travels-app:latest
                    docker push 605134427539.dkr.ecr.us-west-2.amazonaws.com/tours-travels-app:latest
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
