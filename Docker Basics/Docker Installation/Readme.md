##### Setting up Docker



Install packages that allow apt to use repositories over HTTPS:

sudo apt update

sudo apt upgrade -y

sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release



Add Docker's Official GPG Key

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg



Set Up Docker Repository

echo "deb \[arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb\_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null



Install Docker Engine

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io



Check if Docker is installed and running:

sudo systemctl status docker



To run Docker commands without sudo, add your user to the docker group:

sudo usermod -aG docker $USER



Important: Log out and log back in for this change to take effect, or run:

newgrp docker



Test Docker Installation

docker --version



Docker Daemon Not Running

sudo systemctl start docker

sudo systemctl enable docker

