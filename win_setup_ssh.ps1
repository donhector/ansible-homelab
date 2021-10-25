# Install OpenSSH Client and Server
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Set service to automatic and start
Set-Service sshd -StartupType 'Automatic'
Start-Service sshd

# Configure PowerShell as the default OpenSSH shell
# This at time of writing had some issues: https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#known-issues-with-ssh-on-windows)
# New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Configure SSH public key
New-Item -Path "~" -Name ".ssh" -ItemType Directory

# Adjust username accordingly
$git_username =  "donhector"
$response = Invoke-RestMethod -Uri "https://github.com/$git_username.keys"

# Write public key to file
$response | Set-Content -Path "~\.ssh\authorized_keys"

# Adjust sshd_config to disbale password authentication and the authorized keys from the user home 
(Get-Content $env:programdata\ssh\sshd_config) -replace "(^Match Group administrators)",'#$1' | Set-Content $env:programdata\ssh\sshd_config
(Get-Content $env:programdata\ssh\sshd_config) -replace "(^ *AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys)",'#$1' | Set-Content $env:programdata\ssh\sshd_config
(Get-Content $env:programdata\ssh\sshd_config) -replace ".*PasswordAuthentication *yes", "PasswordAuthentication no" | Set-Content $env:programdata\ssh\sshd_config

# Restart the service so changes are applied 
Restart-Service sshd

# Confirm the Firewall rule is configured. It should be created automatically by setup.
Get-NetFirewallRule -Name *ssh*

# There should be a firewall rule named "OpenSSH-Server-In-TCP", which should be enabled.

# If the firewall does not exist, create one.
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
