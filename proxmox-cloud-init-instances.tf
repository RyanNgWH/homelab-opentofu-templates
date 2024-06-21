# Proxmox VM instances (cloud-init templates)
# ---
# Instances in proxmox created using cloud-init templates.

locals {
  # Instances to load
  proxmox_cloud_init_instances = yamldecode(file("proxmox-cloud-init-instances.config.yaml"))

  # Instances configuration files
  proxmox_cloud_init_instance_configs = { for instance in local.proxmox_cloud_init_instances : instance.name => yamldecode(file("configs/instances/${instance.config_name}.config.yaml")) }
}

resource "proxmox_virtual_environment_vm" "cloud_init_instances" {
  for_each = local.proxmox_cloud_init_instance_configs

  # VM configuration
  vm_id       = each.value.vm_id
  name        = each.value.vm_name
  description = each.value.vm_description
  tags        = each.value.vm_tags

  node_name = each.value.vm_node_name
  pool_id   = each.value.vm_resource_pool

  on_boot = each.value.vm_start_on_boot
  startup {
    order      = each.value.vm_startup_order
    up_delay   = each.value.vm_startup_delay
    down_delay = each.value.vm_shutdown_delay
  }

  protection = each.value.vm_enable_protection
  started    = each.value.vm_started

  # System configuration
  agent {
    enabled = each.value.system_qemu_enabled
    trim    = each.value.system_qemu_trim
  }

  bios          = each.value.system_bios
  machine       = each.value.system_machine_type
  scsi_hardware = each.value.system_scsi_hardware

  boot_order = each.value.system_boot_order

  # CPU configuration
  cpu {
    sockets = each.value.cpu_sockets
    cores   = each.value.cpu_cores
    flags   = each.value.cpu_flags
    numa    = each.value.cpu_enable_numa
    type    = each.value.cpu_type
  }

  # Memory configuration
  memory {
    dedicated = each.value.memory_max_size
    floating  = each.value.memory_min_size
  }

  # Storage configuration
  disk {
    interface    = "scsi0"
    datastore_id = each.value.storage_pool
    backup       = each.value.storage_enable_backup
    discard      = each.value.storage_enable_discard ? "on" : "ignore"
    iothread     = each.value.storage_enable_io_threads
    replicate    = each.value.storage_enable_replication
    ssd          = each.value.storage_emulate_ssd
    size         = each.value.storage_size
  }

  # Network configuration
  network_device {
    bridge   = each.value.network_bridge
    firewall = each.value.network_enable_firewall
    vlan_id  = each.value.network_vlan_id
    queues   = each.value.cpu_sockets * each.value.cpu_cores
  }

  # Template clone
  clone {
    node_name = each.value.clone_node_name
    vm_id     = each.value.clone_node_id
    full      = each.value.clone_enable_full_clone
  }

  # Cloud-init configuration
  initialization {
    interface = "ide2"

    dns {
      domain  = each.value.cloud_init_dns_domain
      servers = each.value.cloud_init_dns_servers
    }

    ip_config {
      ipv4 {
        address = each.value.cloud_init_ipv4
        gateway = each.value.cloud_init_ipv4_gateway
      }
    }
  }
}
