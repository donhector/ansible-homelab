# My Ansible home stuff

## Description

This repo contains Ansible code for managing my home machines

The general folder structure can be created with:

```bash
mkdir -p inventories/{production,staging}/{group_vars/group1,host_vars}
touch inventories/{production,staging}/hosts
touch inventories/{production,staging}/group_vars/group1/vars1.yaml
touch inventories/{production,staging}/host_vars/hostname1.yaml
mkdir playbooks/
touch playbooks/{site.yml,playbook1.yaml,playbook2.yaml}
touch ansible.cfg
touch requirements.yaml
```

As a best practice, roles should be kept in their own repo following naming convention `ansible-role-<name>`.
This promotes role reusability as it allows for publishing the roles in Ansible Galaxy and
decoupling the lifecycle of a role from the site. If you do so, then add `roles/` to `.gitignore`

For now I will keep everything simple until I start moving them out to their own repo.

New roles can be created with:

```bash
ansible-galaxy init roles/<rolename>
```

To install any 3rd party roles and collections declared as requirements:

```shell
ansible-galaxy install -r requirements.yml
```

Using `ansible.cfg` allows you to adjust the location where roles will be searched, so I use:

```ini
roles_path = ~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:./roles
```

So that roles installed via Galaxy will be placed in `~/.ansible` (ie. outside of source control) while my custom ones will be in `./roles` (ie: source controlled)

At home I have a couple Windows hosts so these require some "pre-work" for Ansible to be able to manage them. Linux hosts are much easier to setup for Ansible.

The Ansible control box will be another Linux host on my network.

## Appendix

### Windows Pre-requisite: Setup SSH server

I will configure the Windows 10 host to allow Ansible manage it via `SSH` and not `WinRM` (Windows own protocol). At the time of writing (Ansible 2.10) SSH is still considered experimental, but coming from a Linux backgroud I'm more familiar with it. I found the WinRM setup overly complicated despite being described [here](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#winrm-setup)

Windows 10 comes with a copy of [Win-32 OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/releases) server and client. It just needs to be enabled.

Once the OpenSSH feature is enabled, ensure that the Windows firewall will let SSH connections in. Later one can further edit the default rule to restrict by source IP. Additionally the `%programdata%\ssh\sshd_config` can also be tweaked to only allow conections from certain users and groups.

As an extra security measure, the SSH server config file should only use `publickey` as the authentication method, since the `password` authentication method can be brute forced.

Authorized user keys will by default go in `.ssh/authorized_keys`.
If the path is not absolute, it is taken relative to user's home directory (or profile image path). Ex. `c:\users\user`. Note that if the user belongs to the administrator group, `%programdata%/ssh/administrators_authorized_keys` will be used instead.

For simplicity and universality I will disable the use of the `administrators_authorized_keys` file so OpenSSH will default to the well known `~/.ssh/authorized_keys`

In my case I'll leverage my Github account to pull my own public key and then authorize it on the Windows host.

OpenSSH on Windows supports two types of shells: the traditional `cmd` and the newer `powershell`. `cmd` is at the time of writing the most compatible and the one that I use in my playbooks.

I've captured all the above pre-requisites in a Powershell [script](setup_ssh.ps1), which must be executed in an elevated Powershell console.
