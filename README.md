# Docker Swarm cluster provisioning

Repository contains everything to provision a Docker Swarm cluster.

<hr>

# TOC

- [1. Requirements](#1-requirements)
- [2. Proxy requirements](#2-proxy-requirements)
- [3. Configuration](#3-configuration)
- [4. Installation](#4-installation)
- [5. Verification](#5-verification)
- [6. Post installation configuration](#6-post-installation-configuration)
  - [6.1 Portainer](#61-portainer)
  - [6.2 Traefik](#62-traefik)
- [7. Uninstall](#7-uninstall)

<br>

## 1. Requirements

**System requirements**:
- 1 - 4 VMs with minimum of 2 cpus and 4GB RAM each (HDD size is on your preference)
- static IP on all VMs
- supported linux OS: Ubuntu 20/22.04, RedHat/CentOS 7/8, Rocky 8

**Workstation requirements**:
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

**Additional requirements**:
- [VMs OS and Workstation requirements](docs/requirements.md)
- multi manager cluster requires additional load balancer in front of the cluster (HaProxy, NetScaler, etc)

<br>

## 2. Proxy requirements

Access to following external resources are required:

- Access to OS repository (yum/apt)
- Access to Python packages (*.python.org, *.pypi.org, *.pythonhosted.org)
- Access to Docker packages and images (*.docker.com, *.docker.io)

<br>

## 3. Configuration

- Create copy of `inventory/default` directory and name it after your environment, example: `inventory/<environment>/cluster.yml`
- Edit your environment `inventory.ini` file by filling out environment specific configuration values.
- Edit your environment `all-vault.yml` file by filling out environment specific secrets.

> NOTE: Encrypt the `all-vault.yaml` file using `ansible-vault encrypt inventory/<environment>/group_vars/all/all-vault.yml` and providing secure password.

**Inventory file sample**:

```ini
# Server hostnames <environment>-<role>-<index>
[all]
ds-manager-01 ansible_host=127.0.0.11
ds-manager-02 ansible_host=127.0.0.12
ds-worker-01 ansible_host=127.0.0.13
ds-worker-02 ansible_host=127.0.0.14

# Common variables for all hosts
[all:vars]
# User for ssh connections
ansible_user=
# Users private key for passwordless connection
ansible_ssh_private_key_file=~/.ssh/id_rsa
# Become method
ansible_become_method=sudo
# Proxy configuration
; http_proxy=
; https_proxy=
; no_proxy=10.0.0.0/8,127.16.0.0/12,192.168.0.0/16

# Base URL for management deployments
mgmt_hostname=mgmt.example.com

# Gitea deployment hostname
gitea_hostname=gitea.example.com

[manager]
ds-manager-01
ds-manager-02

[worker]
ds-worker-01
ds-worker-02

[swarm:children]
manager
worker
```

**Vault file sample**:

```yaml
#############################################################################################
# Encrypt the file using strong password:
#   ansible-vault encrypt inventory/group_vars/all/all-vault.yml
#
# Passwords with special characters might not work correctly.
# Valid passwords can be created using the following command:
#   tr -cd '[:alnum:]' < /dev/urandom | fold -w16 | head -n1
#
# Files can be encoded in base64 format ussing the following command:
#   base64 -w 0 <file>
#############################################################################################

# Certificate and private key in base64 format
# NOTE: TLS certificates should be issued by trusted certificate authority.
traefik_tls_crt:
traefik_tls_key:

# Traefik credentials
vault_traefik_user:
vault_traefik_pass:
```

<br>

## 4. Installation

Playbook to install and configure Docker Swarm cluster.

```shell
ansible-playbook -i inventory/<environment>/inventory.ini --ask-vault-pass setup.yml
```

Will confiugre the cluster based on provided configuration in inventory files.

<br>

## 5. Verification

SSH into one of the cluster manager nodes and execute following command:

```shell
docker node ls
```

Output should look like this:

```
ID                            HOSTNAME        STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
sltz1m28nda5na01ebv00y5db *   ds-manager-01   Ready     Active         Leader           20.10.17
aceu43odqfz1eh98ffjb6ucrs     ds-manager-02   Ready     Active         Reachable        20.10.17
z0gwvo1s7l4u27nfrm8hhjeay     ds-worker-01    Ready     Active                          20.10.17
```

<br>

## 6. Post installation configuration

In following sections replace `{{ variable }}` with the configured value of `variable`.

### 6.1 Portainer

1. In browser navigate to `{{ mgmt_hostname }}/portainer/`
2. Go through: "New Portainer installation"
   - Please create the initial administrator user
      - Provide your password (`The password must be at least 12 characters long`)
      - Confirm password
      - Uncheck "Allow collection of anonymous statistics. You can find more information about this in our privacy policy."
      - Click "Create user"

### 6.2 Traefik

1. In browser navigate to `{{ mgmt_hostname }}/traefik/dashboard/`.
2. Login with credentials provided in `all-vault.yml` file:
    ```
    vault_traefik_user:
    vault_traefik_pass:
    ```
3. Navigate to "HTTP" and click on "HTTP Routers" tab.
4. Verify that Name: `traefik@docker` and `portainer@docker` are listed in table.

<br>

## 7. Uninstall

Playbook to uninstall Docker Swarm cluster.

```shell
ansible-playbook -i inventory/<environment>/inventory.ini reset.yml
```

Will uninstall the Docker Swarm cluster and reboot the machines.
