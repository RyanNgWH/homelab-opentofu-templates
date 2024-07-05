<!-- @format -->

# Tinynamoo OpenTofu Templates

This project contains the OpenTofu templates for the Tinynamoo infrastructure. All templates are currently build for Proxmox as the provider.

# Requirements

## Local system

The following software must be installed on the local machine before OpenTofu can be used to deploy the virtual machines.

- [OpenTofu](https://opentofu.org/)

## Proxmox

### SSH connection

Certain configurations are not supported by the Proxmox API, therefore, an SSH connection is required to the proxmox host machine.

1. Create a pam user for the SSH connection

   ```bash
   sudo adduser opentofu
   ```

1. Configure the `sudo` privilege for the user (requires passwordless sudo)

   ```bash
   sudo visudo --file=/etc/sudoers.d/opentofu
   ```

   Add the following lines

   ```conf
   opentofu ALL=(root) NOPASSWD: /sbin/pvesm
   opentofu ALL=(root) NOPASSWD: /sbin/qm
   opentofu ALL=(root) NOPASSWD: /usr/bin/tee /var/lib/vz/*
   ```

1. Add SSH public key file to the `~/.ssh/authorized_keys` file of the `opentofu` user.
1. Test the SSH connection and password-less sudo

   ```bash
   ssh -i "/path/to/private/key" opentofu@your-server sudo pvesm apiinfo
   ```

   > **Note:**
   >
   > If you have a clustered proxmox instance, this user has to be created with `sudo` privileges on all nodes in the cluster

### API token

An API token with the following permissions has to be created on your Proxmox instance. Stricter permissions might be possible but these templates have only been tested with the following proxmox priviledges:

- Datastore.Allocate
- Datastore.AllocateSpace
- Datastore.AllocateTemplate
- Datastore.Audit
- Mapping.Modify
- Mapping.Use
- Pool.Allocate
- Sys.Audit
- Sys.Console
- Sys.Modify
- SDN.Use
- VM.Allocate
- VM.Audit
- VM.Clone
- VM.Config.CDROM
- VM.Config.Cloudinit
- VM.Config.CPU
- VM.Config.Disk
- VM.Config.HWType
- VM.Config.Memory
- VM.Config.Network
- VM.Config.Options
- VM.Migrate
- VM.Monitor
- VM.PowerMgmt
- User.Modify

# Usage

## Creating a virtual machine/LXC container

The process of creating a virtual machines & LXC container is very similar. Where applicable, simply substitute `[vm/lxc]` with the respective virtualisation type.

1.  Create a copy of `examples/example.[vm/lxc].instance.config.yaml` (e.g `[vm/lxc].application.config.yaml`) in `configs/instances` and modify the variables as required.
    > The configuration file has to end with `config.yaml` and must be stored in the `configs/instances` or it will not be loaded.
1.  Add the virtual machine/lxc identifier and config file name to `proxmox-vm-cloud-init-instances.config.yaml` (or `proxmox-lxc-instances.config.yaml` for lxc containers)

    ```yaml
    - name: vm-identifer
      config_name: application
    ```

    > If your configuration file is `[vm/lxc].my-application.config.yaml`, use `config_name: my-application`

1.  Install all required plugins by initialising the directory with opentofu

    ```
    tofu init
    ```

1.  Preview the changes to be made using the following command:

    ```
    tofu plan
    ```

1.  If you are satisfied with the changes to be made, run the following command to apply the changes:

    ```
    tofu apply
    ```

    Opentofu will once again display the changes to be made, double check and approve the changes to apply the configuration.

    > **Note:**
    >
    > All virtual machines created here through OpenTofu should be exclusively managed by OpenTofu. Manual editing of the virtual machines elsewhere could lead to drift in the vm state and might be troublesome to fix.

## Adding a firewall alias/ip set/rule

### Firewall alias

1. Add a new entry into `configs/firewall/datacenter.aliases.config.yaml`

   ```yaml
   - name: lan
     cidr: "192.168.1.0/24"
     comment: "[LAN] Entire lan network"
   ```

1. Review and apply the changes

   ```
   tofu apply
   ```

   > All managed instances will have an auto generated firewall alias and do not need to be created manually

### Firewall ip sets

1. Add a new entry into `configs/firewall/datacenter.ipsets.config.yaml`

   ```yaml
   - name: all_lans
     comment: "[LAN1 + LAN2] All lans"

     children:
       - lan1
       - lan2
   ```

   > Each entry in `children` must be a firewall alias

1. Review and apply the changes

   ```
   tofu apply
   ```

### Firewall rule

Firewall rules can only be created for instances that are managed by opentofu (i.e configuration file exists in `configs/instances`).

1. Create a copy of `examples/example.rules.config.yaml` (e.g `application.rules.config.yaml`) in `configs/firewall` and modify the variables as required.

   > **Configuration variables:**
   >
   > - [`presets`](#presets) - predefined firewall rules.
   > - [`specifics`](#specifics) - custom firewall rules.

   > The configuration file must be in the format `<application>.rules.config.yaml` and must be located in the `configs/firewall` directory or it will not be loaded. If your application is named `my-application`, create the file `configs/firewall/my-application.rules.config.yaml`

1. Review and apply the changes

   ```
   tofu apply
   ```

## Adding a PCI resource mapping

1. Create a copy of `examples/example.pci-mapping.config.yaml` (e.g `application-gpu.rules.config.yaml`) in `configs/pci-mappings` and modify the variables as required.

   > The configuration file has to end with `config.yaml` and must be stored in the `configs/pci-mappings` or it will not be loaded.

1. Add the pci mapping identifier and config file name to `proxmox-pci-mappings.config.yaml`

   ```yaml
   - name: mapping-identifier
     config_name: mapping-name
   ```

   > If your configuration file is `application-gpu.config.yaml`, use `config_name: application-gpu`

1. Review and apply the changes

   ```
   tofu apply
   ```

## Removing a resource

1. Find the identifier of the resource to be removed

   ```
   tofu state list
   ```

1. Run the following command with the identifier of the virtual machine to be removed

   ```
   tofu destroy -target <identifier>
   ```

   ### Example

   The following commands will delete the `ansible` virtual machine

   ```
   > tofu state list
   proxmox_virtual_environment_vm.vm_cloud_init["ansible"]
   proxmox_virtual_environment_vm.vm_cloud_init["piped"]

   > tofu destroy -target 'proxmox_virtual_environment_vm.vm_cloud_init["ansible"]'
   ```

# Configuration

Example configuration for each resource type can be found in the `examples` directory.

## Instances

There are 2 types of variables (**required** & **default**).

- **Required variables** - Located at the top of the file, these variables should be modified as there are no default values.

- **Default variables** - Located after the required variables, these variables are prepopulated with the default values that are usually okay. To overwrite them, simply specify the values in the config file.

## Firewall

### Presets

| Preset   | Description                                                                                               | Variables                                                                                                                                                                             |
| -------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `basic`  | Basic firewall rules for most VMs.</br></br>Allows pinging & SSH from LAN & Tiny airport privilege hosts. | -                                                                                                                                                                                     |
| `uptime` | Allows uptime monitoring of HTTPS websites on the host.                                                   | -                                                                                                                                                                                     |
| `web`    | Allows user-specified hosts to access HTTP/HTTPS websites on the host.                                    | `source_alias` - Source hosts</br>`source_alias_is_ipset` - If source is an ip set</br>`source_description` - Description of source hosts</br>`application` - Web application of host |

### Specifics

Refer [here](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_firewall_rules#rule) for description of the supported variables (everything apart from `enabled` & `iface`).

# Notes

[Telmate's proxmox provider](https://github.com/Telmate/terraform-provider-proxmox) was initially used to as the provider for this project. However, due to its limitations it was replaced with [bpg's proxmox provider](https://github.com/bpg/terraform-provider-proxmox).

# FAQ

## Unable to authenticate user over SSH

For tasks that utilises SSH for deployment, you have to first ensure that your SSH private key has been loaded in the `ssh-agent`.

```bash
# Add your ssh key to the ssh-agent
ssh-add "/path/to/your/private/key"

# Verify that the key has been added
ssh-add -L
```

# Notes

## EFI-Disk & Secure boot

The Jellyfin instance requires secure boot to be turned off, however, it is enabled by default as `pre_enrolled_keys` is enabled for the EFI-Disk. This currently cannot be automated as of bpg/proxmox v0.60.1 and has to be manually turned off in the bios.
