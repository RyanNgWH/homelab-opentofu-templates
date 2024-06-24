# Proxmox LXC instances
# ---
# Instances in proxmox created using LXC.

locals {
  # LXC configuration
  proxmox_lxc_config = yamldecode(file("proxmox-lxc-instances.config.yaml"))

  # LXC templates to upload
  proxmox_lxc_templates = { for template in local.proxmox_lxc_config.templates : template.name => template }
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
