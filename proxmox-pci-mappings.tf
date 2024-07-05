# Proxmox PCI hardware mapping configuration
# ---
# PCI hardware configurations on the proxmox datacenter.

locals {
  # Mappings to load
  proxmox_pci_mappings = yamldecode(file("proxmox-pci-mappings.config.yaml"))

  # Mapping configurations
  proxmox_pci_mapping_configs = {
    for device in local.proxmox_pci_mappings : device.name => yamldecode(file("configs/pci-mappings/${device.config_name}.config.yaml"))
  }
}

resource "proxmox_virtual_environment_hardware_mapping_pci" "all-mappings" {
  for_each = local.proxmox_pci_mapping_configs

  name    = each.value.name
  comment = "[Opentofu] ${each.value.comment}"

  map = [
    for mapping in each.value.mappings : {
      id           = mapping.id
      node         = mapping.node
      path         = mapping.path
      iommu_group  = mapping.iommu_group
      subsystem_id = mapping.subsystem_id

      comment = "[Opentofu] ${mapping.comment}"
    }
  ]
}
