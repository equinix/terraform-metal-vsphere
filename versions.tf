terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    metal = {
      source  = "equinix/metal"
      version = "3.2.0-alpha.5"
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
  required_version = ">= 1.3.0"
}
