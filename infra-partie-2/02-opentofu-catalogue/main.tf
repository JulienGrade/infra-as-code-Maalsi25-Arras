terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///Users/juliengrade/.docker/run/docker.sock"
}

resource "docker_network" "catalogue_net" {
  name = "catalogue-net"
}
# Volume pour les données Postgres
resource "docker_volume" "pg_data" {
  name = "catalogue-pg-data"
}

# Conteneur Postgres
resource "docker_container" "postgres" {
  name  = "catalogue-postgres"
  image = "postgres:15-alpine"

  env = [
    "POSTGRES_USER=catalogue",
    "POSTGRES_PASSWORD=catalogue",
    "POSTGRES_DB=catalogue",
  ]

  networks_advanced {
    name = docker_network.catalogue_net.name
  }

  mounts {
    target = "/var/lib/postgresql/data"
    source = docker_volume.pg_data.name
    type   = "volume"
  }

  ports {
    internal = 5432
    external = 5432
  }
}

resource "docker_container" "redis" {
  name  = "catalogue-redis"
  image = "redis:7-alpine"

  networks_advanced {
    name = docker_network.catalogue_net.name
  }

  ports {
    internal = 6379
    external = 6379
  }
}
# Image de l'API catalogue (build local depuis ./api)
resource "docker_image" "catalogue_api" {
  name = "catalogue-api:latest"

  build {
    context = "${path.module}/api"
  }
}
resource "docker_container" "catalogue_api" {
  name  = "catalogue-api"
  image = docker_image.catalogue_api.image_id

  networks_advanced {
    name = docker_network.catalogue_net.name
  }

  # on publie pour tester depuis le navigateur
  ports {
    internal = 3000
    external = 3000
  }

  env = [
    "PORT=3000",
    "PGHOST=catalogue-postgres",
    "PGUSER=catalogue",
    "PGPASSWORD=catalogue",
    "PGDATABASE=catalogue",
    "REDIS_HOST=catalogue-redis",
    "REDIS_PORT=6379"
  ]

  depends_on = [
    docker_container.postgres,
    docker_container.redis
  ]
}

