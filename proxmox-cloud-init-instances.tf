# Proxmox VM instances (cloud-init templates)
# ---
# Instances in proxmox created using cloud-init templates.

variable "instances" {
  type = list(object({
    # VM configuration
    vm_id = number
    vm_name = string
    vm_description = string
    vm_tags = list(string)

    vm_node_name = string
    vm_resource_pool = string

    vm_start_on_boot = bool
    vm_startup_order = number
    vm_startup_delay = number
    vm_shutdown_delay = number

    vm_enable_protection = bool
    vm_started = bool

    # System configuration
    system_qemu_enabled = bool
    system_qemu_trim = bool

    system_bios = string
    system_machine_type = string
    system_scsi_hardware = string

    system_boot_order = list(string)

    # CPU configuration
    cpu_sockets = number
    cpu_cores = number
    cpu_flags = list(string)
    cpu_enable_numa = bool

    # Memory configuration
    memory_max_size = number
    memory_min_size = number

    # Network configuration
    network_vlan_id = number
    network_bridge = string
    network_enable_firewall = bool

    # Storage configuration (cloud-init disk)
    storage_pool = string
    storage_enable_backup = bool
    storage_enable_discard = bool
    storage_enable_io_threads = bool
    storage_enable_replication = bool
    storage_emulate_ssd = bool
    storage_size = number

    # Template clone
    clone_node_name = string
    clone_node_id = number
    clone_enable_full_clone = bool
  }))
  default = []
}

locals {
  # Configuration files to load
  instance_configs = fileset("configs", "*.config.yaml")

  # List of instances
  instances = [
    for config in local.instance_configs : yamldecode(file("configs/${config}"))
  ]
}

# output "temp" {
#   value = local.instances
# }

resource "proxmox_virtual_environment_vm" "vm_cloud_init" {
  count = length(local.instances)

  # VM configuration
  vm_id = local.instances[count.index].vm_id
  name = local.instances[count.index].vm_name
  description = local.instances[count.index].vm_description
  tags = local.instances[count.index].vm_tags

  node_name = local.instances[count.index].vm_node_name
  pool_id = local.instances[count.index].vm_resource_pool

  on_boot = local.instances[count.index].vm_start_on_boot
  startup {
    order = local.instances[count.index].vm_startup_order
    up_delay = local.instances[count.index].vm_startup_delay
    down_delay = local.instances[count.index].vm_shutdown_delay
  }

  protection = local.instances[count.index].vm_enable_protection
  started = local.instances[count.index].vm_started

  # System configuration
  agent {
    enabled = local.instances[count.index].system_qemu_enabled
    trim = local.instances[count.index].system_qemu_trim
  }

  bios = local.instances[count.index].system_bios
  machine = local.instances[count.index].system_machine_type
  scsi_hardware = local.instances[count.index].system_scsi_hardware

  boot_order = local.instances[count.index].system_boot_order

  # CPU configuration
  cpu {
    sockets = local.instances[count.index].cpu_sockets
    cores = local.instances[count.index].cpu_cores
    flags = local.instances[count.index].cpu_flags
    numa = local.instances[count.index].cpu_enable_numa
    type = local.instances[count.index].cpu_type
  }

  # Memory configuration
  memory {
    dedicated = local.instances[count.index].memory_max_size
    floating = local.instances[count.index].memory_min_size
  }

  # Storage configuration
  disk {
    interface = "scsi0"
    datastore_id = local.instances[count.index].storage_pool
    backup = local.instances[count.index].storage_enable_backup
    discard = local.instances[count.index].storage_enable_discard ? "on" : "ignore"
    iothread = local.instances[count.index].storage_enable_io_threads
    replicate = local.instances[count.index].storage_enable_replication
    ssd = local.instances[count.index].storage_emulate_ssd
    size = local.instances[count.index].storage_size
  }

  # Network configuration
  network_device {
    bridge = local.instances[count.index].network_bridge
    firewall = local.instances[count.index].network_enable_firewall
    vlan_id = local.instances[count.index].network_vlan_id
    queues = local.instances[count.index].cpu_sockets * local.instances[count.index].cpu_cores
  }

  # Template clone
  clone {
    node_name = local.instances[count.index].clone_node_name
    vm_id = local.instances[count.index].clone_node_id
    full = local.instances[count.index].clone_enable_full_clone
  }

  # Cloud-init configuration
  initialization {
    interface = "ide2"

    dns {
      domain = local.instances[count.index].cloud_init_dns_domain
      servers = local.instances[count.index].cloud_init_dns_servers
    }

    ip_config {
      ipv4 {
        address = local.instances[count.index].cloud_init_ipv4
        gateway = local.instances[count.index].cloud_init_ipv4_gateway
      }
    }
  }
}