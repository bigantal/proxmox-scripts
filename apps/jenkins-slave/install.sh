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
##   Source: https://www.baeldung.com/ops/jenkins-slave-node-setup
################################################################

step_start "Operating System" "Updating" "Updated"
  pkg_update
  pkg_upgrade

step_start "Dependencies" "Installing" "Installed"
  pkg_add curl wget haveged gpg openjdk-17-jre-headless git openssh-server ca-certificates

step_start "Jenkins User" "Creating" "Created"
  # Define the username and password
  USERNAME="jenkins"
  PASSWORD="jenkins"
  # Create the user
  sudo useradd -m -s /bin/bash "$USERNAME"
  # Set the password for the user
  echo "$USERNAME:$PASSWORD" | sudo chpasswd
  # Add the user to the sudoers file
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$USERNAME"
  # Verify the user creation
  id "$USERNAME"
  # Add the user to the Docker group
  sudo groupadd docker
  sudo usermod -aG docker $USERNAME

step_start "Docker Repository" "Adding" "Added"
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

step_start "Docker" "Installing" "Installed"
  pkg_update
  pkg_add docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  svc_add docker
  svc_start docker

step_start "Environment" "Cleaning" "Cleaned"
  if [ "$EPS_CLEANUP" = true ]; then
    #pkg_del "$EPS_DEPENDENCIES"
    printf "\nNo cleanup for ${EPS_DEPENDENCIES}\n"
  fi
  pkg_clean

step_end "Installation complete"

printf "\nThe IP is ${CLR_CYB}$(os_ip)${CLR}\n\n"
printf "The username is ${CLR_CYB}jenkins${CLR}\n"
printf "The password is ${CLR_CYB}jenkins${CLR}\n\n"
printf "The home folder is ${CLR_CYB}/home/jenkins${CLR}\n\n"
