# Proxmox LXC instances
# ---
# Instances in proxmox created using LXC.

locals {
  # LXC configuration
  proxmox_lxc_config = yamldecode(file("proxmox-lxc-instances.config.yaml"))

  # LXC templates to upload
  proxmox_lxc_templates = { for template in local.proxmox_lxc_config.templates : template.name => template }

  # LXC instances config files
  proxmox_lxc_instance_configs = {
    for instance in local.proxmox_lxc_config.instances : instance.name => yamldecode(file("configs/instances/lxc.${instance.config_name}.config.yaml"))
  }
}

# LXC templates
resource "proxmox_virtual_environment_file" "lxc_templates" {
  for_each = local.proxmox_lxc_templates

  content_type = "vztmpl"
  datastore_id = each.value.datastore_id
  node_name    = each.value.node_name

  source_file {
    path = "files/lxc-templates/${each.value.file_name}"
  }
}

# LXC instances
resource "proxmox_virtual_environment_container" "instances" {
  for_each = local.proxmox_lxc_instance_configs

  # LXC configuration
  vm_id       = each.value.lxc_id
  description = each.value.lxc_description
  tags        = try(each.value.lxc_tags, ["opentofu"])

  node_name  = each.value.lxc_node_name
  protection = try(each.value.lxc_protection, false)

  start_on_boot = try(each.value.lxc_start_on_boot, false)
  startup {
    order      = try(each.value.lxc_startup_order, 100)
    up_delay   = try(each.value.lxc_startup_delay, 0)
    down_delay = try(each.value.lxc_shutdown_delay, 0)
  }

  started      = try(each.value.lxc_started, true)
  unprivileged = try(each.value.lxc_unprivileged, true)
  features {
    nesting = try(each.value.lxc_nesting, true)
  }

  # CPU configuration
  cpu {
    cores = try(each.value.cpu_cores, 1)
  }
  # Memory configuration
  memory {
    dedicated = try(each.value.memory_size, 512)
    swap      = try(each.value.memory_swap, 512)
  }

  # Storage configuration
  disk {
    datastore_id = try(each.value.storage_pool, "local-zfs")
    size         = try(each.value.storage_size, 8)
  }

  initialization {
    # Host configuration
    hostname = each.value.lxc_name

    # Network configuration
    dns {
      domain  = each.value.network_dns_domain
      servers = each.value.network_dns_servers
    }

    ip_config {
      ipv4 {
        address = each.value.network_ipv4
        gateway = each.value.network_ipv4_gateway
      }
    }
  }

  network_interface {
    bridge   = try(each.value.network_bridge, "vmbr0")
    firewall = try(each.value.network_enable_firewall, true)
    name     = try(each.value.network_interface_name, "eth0")
    vlan_id  = each.value.network_vlan_id
  }
  # OS Configuration
  operating_system {
    template_file_id = proxmox_virtual_environment_file.lxc_templates[each.value.os_template_name].id
    type             = each.value.os_template_type
  }

}
