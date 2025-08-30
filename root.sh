#!/bin/sh
ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT="amd64"
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT="arm64"
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                     Reborn Freeroot Foxytoux INSTALLER"
  echo "#"
  echo "#                   Copyright (C) 2024, RecodeStudios.Cloud"
  echo "#                 Copyright (C) 2024, @BlackCatOfficial (soon)"
  echo "#"
  echo "#######################################################################################"
  read -p "Do you want to install Ubuntu Base? (YES/no): " install_ubuntu
fi
case $install_ubuntu in
  [yY][eE][sS])
    echo "Downloading Ubuntu Base image..."
    # The Ubuntu Base image is a compressed tarball, which is much simpler
    # to extract than a Ubuntu Core disk image.
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.xz \
      "https://cdimage.ubuntu.com/ubuntu-base/releases/noble/release/ubuntu-base-24.04.3-base-{$ARCH_ALT}.tar.gz"
    # revert back to jammy to fix
    # wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.xz \
        # "https://cdimage.ubuntu.com/ubuntu-base/releases/jammy/release/ubuntu-base-22.04-base-amd64.tar.gz"
    
    # Extract the tarball into the rootfs directory
    echo "Extracting files..."
    tar -xf /tmp/rootfs.tar.xz -C $ROOTFS_DIR
    
    # Add localhost to /etc/hosts
    echo "127.0.0.1 localhost" >> ${ROOTFS_DIR}/etc/hosts
    ;;
  *)
    echo "Skipping Ubuntu Minimal installation."
    ;;
esac
if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir $ROOTFS_DIR/usr/local/bin -p
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/BlackCatOfficialytb/freeroot/main/proot-${ARCH}"
  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm $ROOTFS_DIR/usr/local/bin/proot -rf
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/BlackCatOfficialytb/freeroot/main/proot-${ARCH}"
    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      break
    fi
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
    sleep 1
  done
  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi
if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.xz /tmp/sbin
  touch $ROOTFS_DIR/.installed
fi
CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'
display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "      ${CYAN}-----> Freeroot Completed ! <----${RESET_COLOR}"
  echo -e "${CYAN}use apt update && apt install <any package> -y${RESET_COLOR}"
}
clear
display_gg
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
