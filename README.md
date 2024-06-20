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

   ```
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

## Creating a virtual machine

1.  Create a copy of `examples/example-providers.config.auto.tfvars` (e.g `providers.config.auto.tfvars`) in the root folder and modify the variables as required.
1.  Create a copy of `examples/example.instance.config.yaml` (e.g `application.config.yaml`) in the `configs` directory and modify the variables as required.
    > The configuration file has to end with `config.yaml` and must be stored in the `configs` folder or it will not be loaded.
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

## Removing a virtual machine

1. Find the index of the instance to be removed
   ```
   tofu state list
   tofu state show proxmox_virtual_environment_vm.vm_cloud_init[index]
   ```
1. Run the following command with the index of the virtual machine to be removed

   ```
   tofu destroy -target proxmox_virtual_environment_vm.vm_cloud_init[index]
   ```

# Configuration

All configuration variables required can be found in `examples/example.instance.config.yaml` and `examples/example-providers.config.auto.tfvars`. There are 2 types of variables (**requied** & **default**).

### Required variables

Located at the top of the file, these variables should be modified to as the default values might not work.

### Default variables

Located after the required variables, these variables are prepopulated with the default values that are usually okay.

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
