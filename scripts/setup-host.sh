#!/bin/bash

# ==================================================================
# This script sets up a Fedora Host to run all the services here
# ==================================================================
# PREREQUISITES:
# - Setup storage devices & mounts
# - Setup physical network interfaces
# - Change variables below

export HOSTNAME="tardis"
export DOMAIN="kemo.labs"

export CONTAINER_WORK_DIR="/opt/workdir/caas"
export VM_WORK_DIR="/opt/workdir/vm"


# ==================================================================
# Networking
# ==================================================================
# Disable IPv6
cat > /etc/sysctl.d/99-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
sysctl -p

# Set bridge udev rules
echo 'ACTION=="add", SUBSYSTEM=="module", KERNEL=="br_netfilter", RUN+="/sbin/sysctl -p /etc/sysctl.d/libvirt-nf-bridge.conf"' > /etc/udev/rules.d/99-bridge.rules

# Set nf bridge config
cat > /etc/sysctl.d/libvirt-nf-bridge.conf <<EOF
net.bridge.bridge-nf-call-ip6tables=0
net.bridge.bridge-nf-call-iptables=0
net.bridge.bridge-nf-call-arptables=0
EOF

# ==================================================================
# Package Management
# ==================================================================
# Add Kopia Repo
rpm --import https://kopia.io/signing-key
cat > /etc/yum.repos.d/kopia.repo <<EOF
[Kopia]
name=Kopia
baseurl=http://packages.kopia.io/rpm/stable/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://kopia.io/signing-key
EOF

# Update base system
dnf update -y

# Install needed packages
dnf install -y nano git wget curl bind-utils bash-completion net-tools jq yq \
  python3 python3-pip python3-argcomplete python3-pip-wheel python3-wheel python3-devel \
  cockpit pcp python3-pcp \
  podman container-tools cockpit-podman pcp-pmda-podman podman-compose \
  virt-install virt-top cockpit-machines libvirt libguestfs-tools \
  kopia \
  make gcc patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel libuuid-devel gdbm-libs libnsl2

# Install pyenv
curl -fsSL https://pyenv.run | bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' > /etc/profile.d/pyenv
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> /etc/profile.d/pyenv
echo 'eval "$(pyenv init - bash)"' >> /etc/profile.d/pyenv

# ==================================================================
# Service Management
# ==================================================================
# Enable services
systemctl enable --now cockpit.socket
systemctl enable --now podman.socket
systemctl enable --now podman.service
systemctl enable --now pmlogger.service
systemctl enable --now libvirtd

# Enable root login to cockpit
echo '# no one' > /etc/cockpit/disallowed-users

# ==================================================================
# Podman Setup
# ==================================================================
# Create Podman Network Directory
mkdir -p /etc/containers/networks/

# ==================================================================
# Libvirt/KVM Setup
# ==================================================================