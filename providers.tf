# OpenTofu providers
# ---
# Opentofu providers available for infrastructure deployment

### Providers
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.87"
    }
  }
}

### Proxmox
## Variables
# Proxmox connection
variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_ssh_username" {
  type      = string
  sensitive = true
}

variable "proxmox_ssh_private_key" {
  type      = string
  sensitive = true
}

## Locals
locals {
  # Proxmox connection
  proxmox_api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
}

## Configuration
provider "proxmox" {
  # Proxmox connection
  endpoint  = var.proxmox_endpoint
  api_token = local.proxmox_api_token

  # SSH
  ssh {
    username    = var.proxmox_ssh_username
    private_key = var.proxmox_ssh_private_key

    agent = true
  }
}
