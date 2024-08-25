pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/Phanendradant/Tours-and-travels-in-php.git'
            }
        }
        stage('Install PHP and Composer') {
            steps {
                sh '''
                if ! [ -x "$(command -v php)" ]; then
                  echo "PHP is not installed. Installing PHP..."
                  sudo apt-get update
                  sudo apt-get install -y php-cli
                else
                  echo "PHP is already installed."
                fi

                if ! [ -x "$(command -v composer)" ]; then
                  echo "Composer is not installed. Installing Composer..."
                  curl -sS https://getcomposer.org/installer | php
                  sudo mv composer.phar /usr/local/bin/composer
                else
                  echo "Composer is already installed."
                fi
                '''
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
