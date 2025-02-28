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
##   Source: https://github.com/bigantal/things-connector/blob/main/orangepi/README.md
################################################################

# Function to check internet connectivity
check_internet() {
    ping -c 1 8.8.8.8 &> /dev/null
    return $?
}

step_start "Internet connection" "Waiting for" "Established"
  while ! check_internet; do
      #echo "Waiting for internet connection..."
      sleep 5
  done

step_start "Operating System" "Updating" "Updated"
  pkg_update
  pkg_upgrade

step_start "Dependencies" "Installing" "Installed"
  pkg_add apt-utils ca-certificates curl gnupg2 software-properties-common

step_start "Plex Repository" "Adding" "Added"
  curl https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plex-archive-keyring.gpg >/dev/null
  # curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
  echo deb [signed-by=/usr/share/keyrings/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
  #echo deb https://downloads.plex.tv/repo/deb/ public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list

step_start "Plex" "Installing" "Installed"
  pkg_update
  pkg_add plexmediaserver
  svc_add plexmediaserver
  svc_start plexmediaserver

step_start "Transmission" "Installing" "Installed"
  pkg_update
  pkg_add transmission-daemon
  svc_add transmission-daemon
  svc_start transmission-daemon



step_start "Environment" "Cleaning" "Cleaned"
  if [ "$EPS_CLEANUP" = true ]; then
    pkg_del "$EPS_DEPENDENCIES"
  fi
  pkg_clean

step_end "Installation complete"

printf "\nThe Plex application should be reachable at ${CLR_CYB}https://$(os_ip):32400/web${CLR}\n\n"
printf "\nThe Transmission application should be reachable at ${CLR_CYB}https://$(os_ip):9091/transmission/web${CLR}\n\n"
