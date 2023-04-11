# Provisionamento de cluster do Docker Swarm

O repositório contém tudo para provisionar um cluster do Docker Swarm.
[Escolher outro idimoma](/README.md)
<hr>

# TOC

- [1. Requisitos](#1-requisitos)
- [2. Requisitos de proxy](#2-proxy-requirements)
- [3. Configuração](#3-configuração)
- [4. Instalação](#4-instalação)
- [5. Verificação](#5-verificação)
- [6. Configuração pós-instalação](#6-configuração-pós-instalação)
   - [6.1 Portainer](#61-portainer)
   - [6.2 Traefik](#62-traefik)
- [7. Gitea](#7-gitea)
   - [7.1 Instalação](#71-instalação)
   - [7.2 Configuração pós-instalação](#72-configuração-pós-instalação)
   - [7.3 Notificação via MS Teams](#73-notification-via-ms-teams)
- [8. Atualização de implantações](#8-deployments-update)
- [9. Desinstalar](#9-desinstalar)

<br>

## 1. Requisitos

**Requisitos de sistema**:
- 1 - 4 VMs com mínimo de 2 cpus e 4 GB de RAM cada (o tamanho do HDD é de sua preferência)
- IP estático em todas as VMs
- SO linux suportado: Ubuntu 20/22.04, RedHat/CentOS 7/8, Rocky 8

**Requisitos da estação de trabalho**:
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

**Requisitos adicionais**:
- Compartilhamento NFS para volumes docker compartilhados em todos os hosts
- [Requisitos de sistema operacional e estação de trabalho de VMs](docs/requirements.md)
- o cluster multigerenciador requer um balanceador de carga adicional na frente do cluster (HaProxy, NetScaler, etc.)

<br>

## 2. Requisitos de procuração

O acesso aos seguintes recursos externos é necessário:

- Acesso ao repositório do sistema operacional (yum/apt)
- Acesso a pacotes Python (*.python.org, *.pypi.org, *.pythonhosted.org)
- Acesso a pacotes e imagens do Docker (*.docker.com, *.docker.io)

<br>

## 3. Configuração

- Crie uma cópia do diretório `inventory/default` e dê o nome do seu ambiente, exemplo: `inventory/<environment>`
- Edite o arquivo `inventory.ini` do ambiente preenchendo os valores de configuração específicos do ambiente.
- Edite o arquivo `all-vault.yml` do seu ambiente preenchendo os segredos específicos do ambiente.

> NOTA: Criptografe o arquivo `all-vault.yaml` usando `ansible-vault encrypt inventório/<ambiente>/group_vars/all/all-vault.yml` e fornecendo uma senha segura.

**Exemplo de arquivo de inventário**:

```ini
# Nomes de host do servidor <ambiente>-<função>-<índice>
[all]
ds-manager-01 ansible_host=127.0.0.11
ds-manager-02 ansible_host=127.0.0.12
ds-worker-01 ansible_host=127.0.0.13
ds-worker-02 ansible_host=127.0.0.14

# Variáveis comuns para todos os hosts
[all:vars]
# Usuário para conexões ssh
ansible_user=
# Chave privada do usuário para conexão sem senha
ansible_ssh_private_key_file=~/.ssh/id_rsa
# Torne-se método
ansible_become_method=sudo
# Argumentos comuns SSH
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
# Configuração de proxy
; http_proxy=
; https_proxy=
; no_proxy=10.0.0.0/8.172.16.0.0/12.192.168.0.0/16

# URL base para todos os tipos de implantações, exemplo: gitea.example.com
# NOTA: URL será usado para implantações de gerenciamento e para Gitea
base_hostname=gitea.example.com

# Configurações de volume compartilhado para implantação do Gitea
share_enable=true
share_type=nfs
share_server=127.0.0.10
share_server_path=/docker_volume

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

**Exemplo de arquivo do Vault**:

```yaml
################################################### ############################################
# Criptografe o arquivo usando uma senha forte:
# ansible-vault criptografar inventário/group_vars/all/all-vault.yml
#
# Senhas com caracteres especiais podem não funcionar corretamente.
# Senhas válidas podem ser criadas usando o seguinte comando:
# tr -cd '[:alnum:]' < /dev/urandom | dobrar -w16 | cabeça -n1
#
# Os arquivos podem ser codificados no formato base64 usando o seguinte comando:
# base64 -w 0 <arquivo>
################################################### ############################################

# Certificado e chave privada no formato base64
# NOTA: Os certificados TLS devem ser emitidos por uma autoridade de certificação confiável.
traefik_tls_crt:
traefik_tls_key:

# Credenciais Traefik
vault_traefik_user:
vault_traefik_pass:
```

<br>

## 4. Instalação

Playbook para instalar e configurar o cluster do Docker Swarm.

```shell
ansible-playbook -i inventário/<ambiente>/inventory.ini --ask-vault-pass setup.yml
```

Irá configurar o cluster com base na configuração fornecida nos arquivos de inventário.

<br>

## 5. Verificação

SSH em um dos nós do gerenciador de cluster e execute o seguinte comando:

```shell
docker node ls
```

A saída deve ficar assim:

```
ID                            HOSTNAME        STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
sltz1m28nda5na01ebv00y5db *   ds-manager-01   Ready     Active         Leader           20.10.17
aceu43odqfz1eh98ffjb6ucrs     ds-manager-02   Ready     Active         Reachable        20.10.17
z0gwvo1s7l4u27nfrm8hhjeay     ds-worker-01    Ready     Active                          20.10.17
```

<br>

## 6. Configuração pós-instalação

Nas seções a seguir, substitua `{{ variável }}` pelo valor configurado de `variável`.

### 6.1 Portêiner

1. Na navegação do navegador