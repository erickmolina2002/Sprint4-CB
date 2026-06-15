terraform {
  required_version = ">= 1.5"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "wellme_back" {
  name = "wellme-back:secure"
}

resource "docker_network" "wellme_net" {
  name = "wellme_net"
}

resource "docker_container" "wellme_back" {
  name  = "wellme-back"
  image = docker_image.wellme_back.image_id

  security_opts = ["no-new-privileges:true"]

  read_only = true
  mounts {
    target = "/tmp"
    type   = "tmpfs"
  }
  mounts {
    target = "/app/logs"
    type   = "tmpfs"
  }

  capabilities {
    drop = ["ALL"]
  }

  memory     = 256
  cpu_shares = 512

  env = [
    "NODE_ENV=production",
    "JWT_SECRET=${var.jwt_secret}",
    "DB_HOST=db",
    "VULN_V1=false",
    "VULN_V2=false",
    "VULN_V3=false",
  ]

  networks_advanced {
    name = docker_network.wellme_net.name
  }
  ports {
    internal = 3000
    external = 3000
  }

  user    = "node"
  restart = "unless-stopped"
}
