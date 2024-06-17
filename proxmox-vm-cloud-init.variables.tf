# Proxmox VM cloud-init template clone
# ---
# Variables for cloning an existing proxmox cloud-init vm template
# Variable details can be found at https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm

# VM configuration
variable "vm_id" {
  type = number
}

variable "vm_name" {
  type = string
}

variable "vm_description" {
  type = string
}

variable "vm_tags" {
  type = list(string)
  default = []
}

variable "vm_node_name" {
  type = string
}

variable "vm_resource_pool" {
  type = string
  default = ""
}

variable "vm_start_on_boot" {
  type = bool
  default = false
}

variable "vm_startup_order" {
  type = number
  default = 100

  validation {
    condition = var.vm_startup_order >= 0

    error_message = "The vm_startup_order variable must be a non-negative number"
  }
}

variable "vm_startup_delay" {
  type = number
  default = 0

    validation {
    condition = var.vm_startup_delay >= 0

    error_message = "The vm_startup_delay variable must be a non-negative number"
  }
}

variable "vm_shutdown_delay" {
  type = number
  default = 0

    validation {
    condition = var.vm_shutdown_delay >= 0

    error_message = "The vm_startup_delay variable must be a non-negative number"
  }
}

variable "vm_enable_protection" {
  type = bool
  default = false
}

variable "vm_started" {
  type = bool
  default = true
}

# System configuration
variable "system_qemu_enabled" {
  type = bool
  default = true
}

variable "system_qemu_trim" {
  type = bool
  default = true
}

variable "system_bios" {
  type = string
  default = "ovmf"

  validation {
    condition = var.system_bios == "ovmf" || var.system_bios == "seabios"

    error_message = "The system_bios variable can only be `ovmf` or `seabios`."
  }
}

variable "system_machine_type" {
  type = string
  default = "q35"

  validation {
    condition = var.system_machine_type == "q35" || var.system_machine_type == "pc"

    error_message = "The system_machine_type variable can only be `q35` or `pc`."
  }
}

variable "system_scsi_hardware" {
  type = string
  default = "virtio-scsi-single"

  validation {
    condition = var.system_scsi_hardware == "lsi" || var.system_scsi_hardware == "lsi53c810" || var.system_scsi_hardware == "virtio-scsi-pci" || var.system_scsi_hardware == "virtio-scsi-single" || var.system_scsi_hardware == "megasas" || var.system_scsi_hardware == "pvscsi"

    error_message = "The system_scsi_hardware variable can only be `lsi`, `lsi53c810`, `virtio-scsi-pci`, `virtio-scsi-single`, `megasas` or `pvscsi`."
  }
}

variable "system_boot_order" {
  type = list(string)
  default = [
    "scsi0"
  ]
}

# CPU configuration
variable "cpu_sockets" {
  type = number
  default = 1
}

variable "cpu_cores" {
  type = number
  default = 1
}

variable "cpu_flags" {
  type = list(string)
  default = [
    "+md-clear",
    "+pcid",
    "+spec-ctrl",
    "+ssbd",
    "+pdpe1gb",
    "+aes"
  ]
}

variable "cpu_enable_numa" {
  type = bool
  default = true
}

variable "cpu_type" {
  type = string
  default = "host"
}

# Memory configuration
variable "memory_max_size" {
  type = number
  default = 1024
}

variable "memory_min_size" {
  type = number
  default = 1024
}

# Network configuration
variable "network_bridge" {
  type = string
  default = "vmbr0"
}

variable "network_enable_firewall" {
  type = bool
  default = true
}

variable "network_vlan_id" {
  type = number
}

# Storage configuration (cloud-init disk)
variable "storage_pool" {
  type = string
  default = "local-lvm"
}

variable "storage_enable_backup" {
  type = bool
  default = true
}

variable "storage_enable_discard" {
  type = bool
  default = true
}

variable "storage_enable_io_threads" {
  type = bool
  default = true
}

variable "storage_enable_replication" {
  type = bool
  default = true
}

variable "storage_emulate_ssd" {
  type = bool
  default = true
}

variable "storage_size" {
  type = number
  default = 8
}

# Template clone
variable "clone_node_name" {
  type = string
}

variable "clone_node_id" {
  type = number
}

variable "clone_enable_full_clone" {
  type = bool
  default = true
}

# Cloud-init configuration
variable "cloud_init_dns_domain" {
  type = string
}

variable "cloud_init_dns_servers" {
  type = list(string)
}

variable "cloud_init_ipv4" {
  type = string
}

variable "cloud_init_ipv4_gateway" {
  type = string
}
