#!/usr/bin/env bash
EPS_BASE_URL=${EPS_BASE_URL:-}
EPS_OS_DISTRO=${EPS_OS_DISTRO:-}
EPS_UTILS_COMMON=${EPS_UTILS_COMMON:-}
EPS_UTILS_DISTRO=${EPS_UTILS_DISTRO:-}
EPS_APP_CONFIG=${EPS_APP_CONFIG:-}
EPS_CLEANUP=${EPS_CLEANUP:-false}
EPS_CT_INSTALL=${EPS_CT_INSTALL:-false}

if [ -z "$EPS_BASE_URL" -o -z "$EPS_OS_DISTRO" -o -z "$EPS_UTILS_COMMON" -o -z "$EPS_UTILS_DISTRO" -o -z "$EPS_APP_CONFIG" ]; then
  printf "Script looded incorrectly!\n\n";
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


step_start "Operating System" "Updating" "Updated"
  pkg_update
  #pkg_upgrade

step_start "Dependencies" "Installing" "Installed"
  pkg_add curl haveged gpg openjdk-17-jre-headless

step_start "MongoDB Repository" "Adding" "Added"
  curl https://pgp.mongodb.com/server-7.0.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-org-server-7.0-archive-keyring.gpg >/dev/null
  echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-org-server-7.0-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null

  step_end "MongoDB Repository Installed"

step_start "UniFi Repository" "Adding" "Added"
  curl https://dl.ui.com/unifi/unifi-repo.gpg | sudo tee /usr/share/keyrings/ubiquiti-archive-keyring.gpg >/dev/null
  echo 'deb [signed-by=/usr/share/keyrings/ubiquiti-archive-keyring.gpg] https://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list > /dev/null

  step_end "UniFi Repository very much added"


step_start "MongoDB" "Installing" "Installed"
  sudo apt update

  sudo apt install -y mongodb-org-server
  sudo systemctl enable mongod
  sudo systemctl start mongod

step_start "UniFi Network Controller" "Installing" "Installed"
  sudo apt update
  sudo apt install unifi

step_start "Enviroment" "Cleaning" "Cleaned"
  yarn cache clean --silent --force >$__OUTPUT
  # find /tmp -mindepth 1 -maxdepth 1 -not -name nginx -exec rm -rf '{}' \;
  if [ "$EPS_CLEANUP" = true ]; then
    pkg_del "$EPS_DEPENDENCIES"
  fi
  pkg_clean

step_end "Installation complete"
printf "\nNginx Proxy Manager should be reachable at ${CLR_CYB}https://$(os_ip):8443${CLR}\n\n"
