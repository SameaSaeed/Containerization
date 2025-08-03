terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Create a custom network
resource "docker_network" "iac_network" {
  name = "terraform-iac-network"
  driver = "bridge"
}

# Create volume for database
resource "docker_volume" "postgres_data" {
  name = "terraform-postgres-data"
}

# Database container
resource "docker_container" "database" {
  name  = "terraform-postgres"
  image = "postgres:13"
  
  env = [
    "POSTGRES_DB=terraformdb",
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=terraform123"
  ]
  
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
  
  networks_advanced {
    name = docker_network.iac_network.name
  }
  
  ports {
    internal = 5432
    external = 5433
  }
  
  restart = "unless-stopped"
}

# Web application container
resource "docker_container" "web_app" {
  count = 2
  name  = "terraform-web-${count.index + 1}"
  image = "docker-iac-web:latest"
  
  env = [
    "ENVIRONMENT=terraform-managed",
    "DATABASE_URL=postgresql://postgres:terraform123@terraform-postgres:5432/terraformdb"
  ]
  
  networks_advanced {
    name = docker_network.iac_network.name
  }
  
  ports {
    internal = 5000
    external = 5001 + count.index
  }
  
  depends_on = [docker_container.database]
  restart = "unless-stopped"
}