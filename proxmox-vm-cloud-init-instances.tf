# Proxmox VM instances (cloud-init templates)
# ---
# Instances in proxmox created using cloud-init templates.

locals {
  # Instances to load
  proxmox_cloud_init_instances = yamldecode(file("proxmox-vm-cloud-init-instances.config.yaml"))

  # Instances configuration files
  proxmox_cloud_init_instance_configs = { for instance in local.proxmox_cloud_init_instances : instance.name => yamldecode(file("configs/instances/vm.${instance.config_name}.config.yaml")) }
}

# Cloud-init network configuration
resource "proxmox_virtual_environment_file" "cloud_init_instances_network_configs" {
  for_each = local.proxmox_cloud_init_instance_configs

  content_type = "snippets"
  datastore_id = try(each.value.cloud_init_datastore, "local")
  node_name    = each.value.vm_node_name

  source_raw {
    file_name = "${each.value.vm_id}_${each.value.vm_name}_cloud-init-network-config.yml"

    data = <<-EOF
      #cloud-config
      network:
        version: 2
        ethernets:
          enp6s18:
            match:
              name: enp6s18
            addresses:
              - ${each.value.cloud_init_ipv4}
            gateway4: ${each.value.cloud_init_ipv4_gateway}
            nameservers:
              search: ${each.value.cloud_init_dns_domain}
              addresses: ${join(",", each.value.cloud_init_dns_servers)}
    EOF
  }
}

resource "proxmox_virtual_environment_vm" "cloud_init_instances" {
  for_each = local.proxmox_cloud_init_instance_configs

  # VM configuration
  vm_id       = each.value.vm_id
  name        = each.value.vm_name
  description = each.value.vm_description
  tags        = try(each.value.vm_tags, ["opentofu"])

  node_name = each.value.vm_node_name

  on_boot = try(each.value.vm_start_on_boot, false)
  startup {
    order      = try(each.value.vm_startup_order, 100)
    up_delay   = try(each.value.vm_startup_delay, 0)
    down_delay = try(each.value.vm_shutdown_delay, 0)
  }

  protection = try(each.value.vm_enable_protection, false)
  started    = try(each.value.vm_started, true)

  purge_on_destroy                     = try(each.value.vm_purge_on_destroy, "true")
  delete_unreferenced_disks_on_destroy = try(each.value.vm_delete_unreferenced_disks, "true")

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
    units   = try(each.value.cpu_units, 1024)
  }

  # Memory configuration
  memory {
    dedicated = try(each.value.memory_max_size, 1024)
    floating  = try(each.value.memory_min_size, 1024)
  }

  # Storage configuration
  disk {
    interface    = "scsi0"
    datastore_id = try(each.value.storage_pool, "local-zfs")
    backup       = try(each.value.storage_enable_backup, true)
    discard      = try(each.value.storage_enable_discard ? "on" : "ignore", "on")
    iothread     = try(each.value.storage_enable_io_threads, true)
    replicate    = try(each.value.storage_enable_replication, true)
    ssd          = try(each.value.storage_emulate_ssd, true)
    size         = try(each.value.storage_size, 8)
  }

  dynamic "disk" {
    for_each = try(each.value.database_disks, [])
    iterator = db

    content {
      interface    = db.value.database_interface
      datastore_id = db.value.database_pool
      backup       = try(db.value.database_enable_backup, true)
      discard      = try(db.value.database_enable_discard ? "on" : "ignore", "on")
      iothread     = try(db.value.database_enable_io_threads, true)
      replicate    = try(db.value.database_enable_replication, true)
      ssd          = try(db.value.database_emulate_ssd, true)
      size         = try(db.value.database_size, 8)
    }
  }

  dynamic "efi_disk" {
    for_each = try(each.value.efi_disk, [])
    iterator = efi

    content {
      datastore_id      = try(each.value.storage_pool, "local-zfs")
      file_format       = try(efi.value.file_format, "raw")
      type              = try(efi.value.type, "4m")
      pre_enrolled_keys = try(efi.value.pre_enrolled_keys, true)
    }
  }

  tpm_state {
    datastore_id = try(each.value.storage_pool, "local-zfs")
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
    datastore_id = try(each.value.storage_pool, "local-zfs")
    interface    = "ide2"

    dns {
      domain = each.value.cloud_init_dns_domain
    }

    network_data_file_id = proxmox_virtual_environment_file.cloud_init_instances_network_configs[each.key].id
  }

  # PCI passthrough configuration
  dynamic "hostpci" {
    for_each = try(each.value.pci_devices, [])
    iterator = device

    content {
      device  = device.value.device
      mapping = proxmox_virtual_environment_hardware_mapping_pci.all-mappings[device.value.mapping].name
      pcie    = try(device.value.pcie, true)
      rombar  = try(device.value.rombar, true)
      xvga    = try(device.value.xvga, false)
    }
  }
}
