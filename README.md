# Homelab Ansible IaC

This repo contains Ansible code for managing my homelab

The general folder structure can be created with"

```bash
mkdir -p inventories/{production,staging}/{group_vars/group1,host_vars}
touch inventories/{production,staging}/hosts
touch inventories/{production,staging}/group_vars/group1/vars1.yaml
touch inventories/{production,staging}/host_vars/hostname1.yaml
mkdir playbooks/
touch playbooks/{site.yml,devenv.yaml,server.yaml}
mkdir -p group_vars host_vars
touch group_vars/all.yaml
touch ansible.cfg
touch requirements.yaml
echo "roles/" > .gitignore
```

As a best practice, roles should be kept in their own repo following naming convention `ansible-role-<name>`.
This promotes role reusability as it allows for publishing the roles in Ansible Galaxy and
decoupling the lifecycle of a role from the site. If you do so, then add `roles/` to `.gitignore`

For now I will keep the roles in the site repo until I start moving them out to their own repo.

New roles can be created with:

```bash
ansible-galaxy init roles/<rolename>
```

To install any roles and collections declared as requirements:

```bash
ansible-galaxy install -r requirements.yml
```

Using `ansible.cfg` allows us to adjust the location where roles will be searched.

I use:

`roles_path = ~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:./roles`

So that roles installed via Galaxy will be placed in `~/.ansible` while still being able to use our custom ones from `./roles`


## Windows 10 Developement machine

I recently got a new Windows 10 Pro laptop, and this time I wanted to fully automate its configuration. Since Ansible supports configuring Windows 10 hosts I wanted to give it a go. While I'm very familiar with Ansible, I never had the oportunity to work with Windows hosts. This should be fun!

Oh by the way, the Ansible control box will be another Linux host on my network.

### Windows Pre-requisite: Setup SSH server

I will configure the Windows 10 host to allow Ansible manage it via SSH and not WinRM (Windows own protocol). At the time of writing (Ansible 2.10) SSH is still considered experimental, but coming from a Linux backgroud I'm more familiar with it. I found the WinRM setup overly complicated despite being described [here](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#winrm-setup)

Windows 10 comes with a copy of [Win-32 OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/releases) server and client. It just needs to be enabled.

Once the OpenSSH feature is enabled, ensure that the Windows firewall will let SSH connections in. One can further edit the default rule to restrict by source IP. Additionally the `%programdata%\ssh\sshd_config` can also be tweaked to only allow conections from certain users and groups.

As an extra security measure, the SSH server config file should only use `publickey` as the authentication method, since the `password` authentication method can be brute forced.

Authorized user keys will by default go in `.ssh/authorized_keys`. If the path is not absolute, it is taken relative to user's home directory (or profile image path). Ex. c:\users\user. Note that if the user belongs to the administrator group, `%programdata%/ssh/administrators_authorized_keys` will be used instead. For simplicity and universality I will disable the use of the `administrators_authorized_keys` file so OpenSSH will default to the well known `~/.ssh/authorized_keys`

In my case I'll leverage Github to pull my public key as an authorized on the Windows host.

OpenSSH on Windows supports two types of shells: the traditional `cmd` and the newer `powershell`. `cmd` is at the time of writing the most compatible.

All the above is captured in the Powershell script below, which must be executed in an elevated Powershell console:

```Powershell
# Install the OpenSSH Client and Server
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Set service to automatic and start
Set-Service sshd -StartupType 'Automatic'
Start-Service sshd

# Configure PowerShell as the default OpenSSH shell
# This at time of writing had some issues: https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#known-issues-with-ssh-on-windows)
# New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Confirm the Firewall rule is configured. It should be created automatically by setup.
Get-NetFirewallRule -Name *ssh*
# There should be a firewall rule named "OpenSSH-Server-In-TCP", which should be enabled
# If the firewall does not exist, create one
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Configure SSH public key
New-Item -Path "~" -Name ".ssh" -ItemType Directory

# Adjust username accordingly
$git_username =  "donhector"
$response = Invoke-RestMethod -Uri "https://github.com/$git_username.keys"

# Write public key to file
$response | Set-Content -Path "~\.ssh\authorized_keys"

# Adjust sshd_config to disbale password authentication and the authorized keys from the user home 
(Get-Content %programdata%\ssh\sshd_config) -replace "(^Match Group administrators)",'#$1' | Set-Content %programdata%\ssh\sshd_config
(Get-Content %programdata%\ssh\sshd_config) -replace "(^ *AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys",'#$1' | Set-Content %programdata%\ssh\sshd_config
(Get-Content %programdata%\ssh\sshd_config) -replace ".*PasswordAuthentication *yes", "PasswordAuthentication no" | Set-Content %programdata%\ssh\sshd_config

# Restart the service so changes are applied 
Restart-Service sshd
```

