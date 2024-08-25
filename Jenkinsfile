pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        KUBECONFIG = '/path/to/your/kubeconfig'  // Update this path to your actual kubeconfig
    }
    stages {
        stage('Setup Environment') {
            steps {
                sh '''
                echo "Installing necessary packages..."
                sudo apt-get update
                sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

                echo "Adding Jenkins GPG key..."
                curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

                echo "Adding Jenkins repository..."
                echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

                sudo apt-get update

                echo "Installing Jenkins and Docker..."
                sudo apt-get install -y awscli jenkins docker.io
                sudo systemctl start jenkins
                sudo systemctl enable jenkins

                # Adding Jenkins and current user to the docker group
                sudo usermod -aG docker $USER
                sudo usermod -aG docker jenkins
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
