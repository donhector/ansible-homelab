Windows 10
=========

A simple role to configure my Windows 10 based laptop.

This role includes tasks for:

- Installing chocolatey packages
- Installing Office and activating it
- Installing WLS2 (Windows Subsystem for Linux)
- Installing VSCode
- Installing MS Windows Terminal
- Installing Windows Updates

Requirements
------------

For Ansible to manage Windows hosts, first the hosts need to be configured to be remotely managed.

Remote managemenet can be done using either WinRM or SSH.

In my case I prefer SSH for simplicity and universality, despite still being considered experimental in Ansible 2.10

[Here](https://gist.github.com/donhector/5d86b568c290ff6ffc09a9b7b48bbd66#file-enablesshforansible-ps1) is the script I run on my Windows 10 hosts to let Ansible manage them. It must be run it from an elevated Powershell window. The script sets up and SSH server on the host and pre-authorizes my public key for passwordless SSH connections.

Role Variables
--------------

`windows10_chocolatey_packages` : List of chocolatey packages to install
`windows10_vscode_extensions` : List of VsCode extensions to install
`windows10_wsl2_distro` : Windows Subsystem for Linux distro to install
`windows10_wsl2_memory`: Memory allocated to the Windows Subsystem for Linux
`windows10_wsl2_processors`: Processors allocated to the Windows Subsystem for Linux

Dependencies
------------

None

Example Playbook
----------------

```yaml
  - name: "Setup Windows 10 host"
    hosts: windows10
    roles:
      - role: windows10
```

License
-------

BSD

Author Information
------------------

github.com/donhector
