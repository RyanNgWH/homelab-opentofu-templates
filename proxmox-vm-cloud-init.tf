# Proxmox VM cloud-init template clone
# ---
# Clone an existing proxmox cloud-init vm template

locals {
  timestamp = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())

  description = <<-EOT
    ${var.vm_description}

    Updated on: ${local.timestamp}
    EOT

  storage_discard = var.storage_enable_discard ? "on" : "ignore"

  multiqueue = var.cpu_sockets * var.cpu_cores
}

resource "proxmox_virtual_environment_vm" "vm_cloud_init" {
  # VM configuration
  vm_id = "${var.vm_id}"
  name = "${var.vm_name}"
  description = "${local.description}"
  tags = var.vm_tags

  node_name = "${var.vm_node_name}"
  pool_id = "${var.vm_resource_pool}"

  on_boot = "${var.vm_start_on_boot}"
  startup {
    order = "${var.vm_startup_order}"
    up_delay = "${var.vm_startup_delay}"
    down_delay = "${var.vm_shutdown_delay}"
  }

  protection = "${var.vm_enable_protection}"
  started = "${var.vm_started}"

  # System configuration
  agent {
    enabled = "${var.system_qemu_enabled}"
    trim = "${var.system_qemu_trim}"
  }

  bios = "${var.system_bios}"
  machine = "${var.system_machine_type}"
  scsi_hardware = "${var.system_scsi_hardware}"

  boot_order = var.system_boot_order

  # CPU configuration
  cpu {
    sockets = "${var.cpu_sockets}"
    cores = "${var.cpu_cores}"
    flags = var.cpu_flags
    numa = "${var.cpu_enable_numa}"
    type = "${var.cpu_type}"
  }

  # Memory configuration
  memory {
    dedicated = "${var.memory_max_size}"
    floating = "${var.memory_min_size}"
  }

  # Storage configuration
  disk {
    interface = "scsi0"
    datastore_id = "${var.storage_pool}"
    backup = "${var.storage_enable_backup}"
    discard = "${local.storage_discard}"
    iothread = "${var.storage_enable_io_threads}"
    replicate = "${var.storage_enable_replication}"
    ssd = "${var.storage_emulate_ssd}"
    size = "${var.storage_size}"
  }

  # Network configuration
  network_device {
    bridge = "${var.network_bridge}"
    firewall = "${var.network_enable_firewall}"
    vlan_id = "${var.network_vlan_id}"
    queues = "${local.multiqueue}"
  }

  # Template clone
  clone {
    node_name = "${var.clone_node_name}"
    vm_id = "${var.clone_node_id}"
    full = "${var.clone_enable_full_clone}"
  }

  # Cloud-init configuration
  initialization {
    interface = "ide2"

    dns {
      domain = "${var.cloud_init_dns_domain}"
      servers = var.cloud_init_dns_servers
    }

    ip_config {
      ipv4 {
        address = "${var.cloud_init_ipv4}"
        gateway = "${var.cloud_init_ipv4_gateway}"
      }
    }
  }
}