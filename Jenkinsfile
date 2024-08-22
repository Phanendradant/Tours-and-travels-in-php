pipeline {
    agent any
    stages {
        stage('Clone Repository') {
            steps {
                git 'https://github.com/projectworldsofficial/Tours-and-travels-in-php'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    sh "./docker.sh"
                    dockerImage = docker.build("tours-travels-app:${env.BUILD_ID}")
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    docker.withRegistry("https://<aws_account_id>.dkr.ecr.us-west-2.amazonaws.com", "ecr:us-west-2:aws") {
                        dockerImage.push('latest')
                    }
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                script {
                    sh 'helm upgrade --install tours-travels-app ./tours-travels-chart --set image.tag=latest'
                }
            }
        }
    }
}
