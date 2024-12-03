terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.0.0"
    }
  }
}

provider "docker" {
  # Añadir para Windows si es necesario:
  # host = "npipe:////.//pipe//docker_engine"
}

resource "docker_image" "jenkins_image" {
  name = "jenkins/jenkins:lts"
}

resource "docker_container" "jenkins_container" {
  image = docker_image.jenkins_image.name
  name  = "jenkins-container"
  ports {
    internal = 8080
    external = 8080
  }
  volumes {
    volume_name    = docker_volume.jenkins_data.name
    container_path = "/var/jenkins_home"
  }
}
