terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    metal = {
      source = "equinix/metal"
      version = "~> 1.1"
    }
    random = {
      source = "hashicorp/random"
    }
    template = {
      source = "hashicorp/template"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source = "hashicorp/local"
    }
  }
  required_version = ">= 0.14"
}
