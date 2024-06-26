# Proxmox VM instances (cloud-init templates)
# ---
# Instances in proxmox created using cloud-init templates.

locals {
  # Instances to load
  proxmox_cloud_init_instances = yamldecode(file("proxmox-vm-cloud-init-instances.config.yaml"))

  # Instances configuration files
  proxmox_cloud_init_instance_configs = { for instance in local.proxmox_cloud_init_instances : instance.name => yamldecode(file("configs/instances/vm.${instance.config_name}.config.yaml")) }
}

resource "proxmox_virtual_environment_vm" "cloud_init_instances" {
  for_each = local.proxmox_cloud_init_instance_configs

  # VM configuration
  vm_id       = each.value.vm_id
  name        = each.value.vm_name
  description = each.value.vm_description
  tags        = try(each.value.vm_tags, ["opentofu"])

  node_name = each.value.vm_node_name
  pool_id   = try(each.value.vm_resource_pool, "")

  on_boot = try(each.value.vm_start_on_boot, false)
  startup {
    order      = try(each.value.vm_startup_order, 100)
    up_delay   = try(each.value.vm_startup_delay, 0)
    down_delay = try(each.value.vm_shutdown_delay, 0)
  }

  protection = try(each.value.vm_enable_protection, false)
  started    = try(each.value.vm_started, true)

  # System configuration
  agent {
    enabled = try(each.value.system_qemu_enabled, true)
    trim    = try(each.value.system_qemu_trim, true)
  }

  bios          = try(each.value.system_bios, "ovmf")
  machine       = try(each.value.system_machine_type, "q35")
  scsi_hardware = try(each.value.system_scsi_hardware, "virtio-scsi-single")

  boot_order = try(each.value.system_boot_order, ["scsi0"])

  # CPU configuration
  cpu {
    sockets = try(each.value.cpu_sockets, 1)
    cores   = try(each.value.cpu_cores, 1)
    flags   = try(each.value.cpu_flags, ["+md-clear", "+pcid", "+spec-ctrl", "+ssbd", "+pdpe1gb", "+aes"])
    numa    = try(each.value.cpu_enable_numa, true)
    type    = try(each.value.cpu_type, "host")
  }

  # Memory configuration
  memory {
    dedicated = try(each.value.memory_max_size, 1024)
    floating  = try(each.value.memory_min_size, 1024)
  }

  # Storage configuration
  disk {
    interface    = "scsi0"
    datastore_id = try(each.value.storage_pool, "local-lvm")
    backup       = try(each.value.storage_enable_backup, true)
    discard      = try(each.value.storage_enable_discard ? "on" : "ignore", true)
    iothread     = try(each.value.storage_enable_io_threads, true)
    replicate    = try(each.value.storage_enable_replication, true)
    ssd          = try(each.value.storage_emulate_ssd, true)
    size         = try(each.value.storage_size, 8)
  }

  tpm_state {
    datastore_id = try(each.value.storage_pool, "local-lvm")
  }

  # Network configuration
  network_device {
    bridge   = try(each.value.network_bridge, "vmbr0")
    firewall = try(each.value.network_enable_firewall, true)
    vlan_id  = each.value.network_vlan_id
    queues   = each.value.cpu_sockets * each.value.cpu_cores
  }

  # Template clone
  clone {
    node_name = each.value.clone_node_name
    vm_id     = each.value.clone_node_id
    full      = try(each.value.clone_enable_full_clone, true)
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
