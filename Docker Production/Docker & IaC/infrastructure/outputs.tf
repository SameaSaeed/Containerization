output "web_app_urls" {
  description = "URLs of the web applications"
  value = [
    for container in docker_container.web_app :
    "http://localhost:${container.ports[0].external}"
  ]
}

output "database_port" {
  description = "Database external port"
  value = docker_container.database.ports[0].external
}

output "network_name" {
  description = "Docker network name"
  value = docker_network.iac_network.name
}