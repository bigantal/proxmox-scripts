#!/usr/bin/env bash

EPS_BASE_URL=${EPS_BASE_URL:-}
EPS_OS_DISTRO=${EPS_OS_DISTRO:-}
EPS_UTILS_COMMON=${EPS_UTILS_COMMON:-}
EPS_UTILS_DISTRO=${EPS_UTILS_DISTRO:-}
EPS_APP_CONFIG=${EPS_APP_CONFIG:-}
EPS_CLEANUP=${EPS_CLEANUP:-false}
EPS_CT_INSTALL=${EPS_CT_INSTALL:-false}

if [ -z "$EPS_BASE_URL" -o -z "$EPS_OS_DISTRO" -o -z "$EPS_UTILS_COMMON" -o -z "$EPS_UTILS_DISTRO" -o -z "$EPS_APP_CONFIG" ]; then
  printf "Script loaded incorrectly!\n\n";
  exit 1;
fi

source <(echo -n "$EPS_UTILS_COMMON")
source <(echo -n "$EPS_UTILS_DISTRO")
source <(echo -n "$EPS_APP_CONFIG")

pms_bootstrap
pms_settraps

if [ $EPS_CT_INSTALL = false ]; then
  pms_header
  pms_check_os
fi

EPS_OS_ARCH=$(os_arch)
EPS_OS_CODENAME=$(os_codename)
EPS_OS_VERSION=${EPS_OS_VERSION:-$(os_version)}

################################################################
##   Source: https://alexhernandez.info/articles/infrastructure/how-to-install-docker-using-ansible/
################################################################

step_start "Operating System" "Updating" "Updated"
  pkg_update
  pkg_upgrade

step_start "Dependencies" "Installing" "Installed"
  pkg_add openssh-server

step_start "SSH" "Configuring" "Configured"
  # Backup the original sshd_config file
  # sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
  # Enable root login
  # sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
  # Restart SSH service to apply changes
  # sudo systemctl restart ssh

  # Ensure the .ssh directory exists for the root user
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  # Add a public key to the authorized_keys file
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDy9EytbmtV6RecCl4Rjpom+WG/zsjhzK3NgoluowHVY jenkins@example.com" >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys

step_start "Environment" "Cleaning" "Cleaned"
  if [ "$EPS_CLEANUP" = true ]; then
    pkg_del "$EPS_DEPENDENCIES"
  fi
  pkg_clean

step_end "Installation complete"

printf "\nThe IP is ${CLR_CYB}$(os_ip)${CLR}\n\n"
