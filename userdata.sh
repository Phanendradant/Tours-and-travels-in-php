  # User data script to install Jenkins, Docker, Helm, Prometheus, Grafana and kubectl
    #!/bin/bash
sudo apt install default-jre
sudo apt install git -y
git clone https://github.com/Phanendradant/Tours-and-travels-in-php.git
# Update and upgrade the instance
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Add Jenkins user to Docker group
sudo usermod -aG docker jenkins

# Install necessary Jenkins plugins (optional)
sudo su - jenkins -s /bin/bash -c "curl -L https://get.jenkins.io/war-stable/2.332.2/jenkins.war -o /var/lib/jenkins/jenkins.war"
sudo su - jenkins -s /bin/bash -c "java -jar /var/lib/jenkins/jenkins.war --httpPort=8080 &"

# Open necessary ports for Jenkins and Docker
sudo ufw allow 8080  # Jenkins
sudo ufw allow 2376  # Docker
sudo ufw enable

# Clone your repository and set up Jenkins job (manual steps may be required)
# Note: Replace the following repository URL with your actual repository
cd /var/lib/jenkins
git clone https://github.com/Phanendradant/Tours-and-travels-in-php.git

# Example to add a Jenkins job via Jenkins CLI or by configuring through the Jenkins UI:
# You can configure a Jenkins job manually via the UI to build and deploy the Docker image using the Dockerfile.

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add Helm repositories for Prometheus and Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus using Helm
kubectl create namespace monitoring
helm install prometheus prometheus-community/prometheus --namespace monitoring

# Install Grafana using Helm
helm install grafana grafana/grafana --namespace monitoring

# Wait for Grafana to be ready and get the admin password
echo "Waiting for Grafana to be ready..."
sleep 120  # Wait for Grafana to initialize (adjust time as needed)

# Get Grafana admin password
grafana_admin_password=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana admin password: $grafana_admin_password"

# Forward Grafana port to access the UI
kubectl port-forward --namespace monitoring svc/grafana 3000:80 &
echo "Grafana is available at http://localhost:3000"

# Open necessary ports for Grafana and Prometheus
sudo ufw allow 3000  # Grafana
sudo ufw allow 9090  # Prometheus
sudo ufw enable
