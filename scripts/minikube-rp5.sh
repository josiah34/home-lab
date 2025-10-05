#!/bin/bash 

# This is a script to setup minikube on rasperrypi 5 

# Add the 

# Function to install Docker if not installed 

install_docker () {
  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  # Install Docker packages
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Add session user to docker group to be able to run docker commands without sudo 
  REAL_USER=$(logname)
  usermod -aG docker "$REAL_USER"
  echo "✅ Added $REAL_USER to docker group."
}

install_kubectl () {
  # Download binary 
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
  
  # Download binary checksum 
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl.sha256"
  # Validate binary
  if echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check --status; then
    echo "✅ kubectl binary validated successfully."
  else
    echo "❌ Checksum validation failed! Aborting."
    exit 1
  fi 
  
  # Install Kubectl 
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  
  # Check install 
  if  command -v kubectl &> /dev/null; then
    echo "✅ Kubectl succesfully installed"
  else
    echo "❌ Kubectl install failed"
    echo "Exiting...."
    exit 1
  fi 
}

# Check if the user is running script with sudo privileges 

if [[ "$EUID" -ne 0 ]]; then 
  echo "Error: Please run the script with sudo"
  exit 1
fi

# Check if Docker is installed and install it if not and set it up 

echo "🚀 STEP 1: Checking if Docker is installed..." 

if command -v docker &> /dev/null; then 
  echo "Docker is installed" 
else 
  echo "Docker is not installed. Installing docker..."
  install_docker
  echo "Docker has been installed. Continuing..."
fi


echo "🚀 STEP 2: Checking if Kubectl is installed..." 

if command -v kubectl &> /dev/null; then
  echo "✅ kubectl is already installed."
else
  install_kubectl 
fi 
  

echo "🚀 Step 3: Checking if Minikube is installed..."
if command -v minikube &> /dev/null; then
  echo "Minikube already installed"
else
  # Download binary  
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_arm64.deb
  sudo dpkg -i minikube_latest_arm64.deb
fi
echo "Please logout of current session and login again before starting minikube"