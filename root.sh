#!/bin/sh
ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
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
  read -p "Do you want to install Ubuntu? (YES/no): " install_ubuntu
fi
case $install_ubuntu in
  [yY][eE][sS])
    echo "Downloading Ubuntu Core image..."
    # The original script downloaded a compressed tarball for ubuntu-base.
    # wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      # "https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.3-base-${ARCH_ALT}.tar.gz"
    # tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
    # We are now using ubuntu-core, which is a disk image that requires
    # a different process of mounting and copying files.
    
    # Download the compressed Ubuntu Core disk image
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/ubuntu-core-24-${ARCH_ALT}.img.xz \
      "https://cdimage.ubuntu.com/ubuntu-core/24/stable/current/ubuntu-core-24-${ARCH_ALT}.img.xz"
    
    # Decompress the disk image
    unxz /tmp/ubuntu-core-24-${ARCH_ALT}.img.xz
    
    # Define the path to the uncompressed image
    CORE_IMG_PATH="/tmp/ubuntu-core-24-${ARCH_ALT}.img"
    
    # Find the offset of the writable root partition (the one with ext4)
    # The 'parted' command is used here to find the start byte of the partition.
    # This is a critical step because a disk image is not a simple tarball.
    ROOT_PARTITION_OFFSET=$(parted -s "${CORE_IMG_PATH}" unit B print | grep 'ext4' | awk '{print $2}' | sed 's/B//')
    
    # Check if the offset was found
    if [ -z "$ROOT_PARTITION_OFFSET" ]; then
      echo "Failed to find the root partition offset."
      exit 1
    fi
    
    echo "Found root partition at offset: ${ROOT_PARTITION_OFFSET} bytes"
    
    # Make the losetup binary executable
    chmod +x ./losetup

    # Create a loop device using your prepared tool and mount the partition
    loop_device=$(./losetup --show -f -o "${ROOT_PARTITION_OFFSET}" "${CORE_IMG_PATH}")
    
    if [ -z "$loop_device" ]; then
      echo "Failed to create a loop device."
      exit 1
    fi
    
    mkdir -p /tmp/mount_core
    mount "${loop_device}" /tmp/mount_core
    
    # Copy the contents of the mounted root partition to the ROOTFS_DIR
    echo "Copying files from Ubuntu Core image..."
    cp -a /tmp/mount_core/* "${ROOTFS_DIR}"
    
    # Clean up the temporary mount point and loop device
    umount /tmp/mount_core
    ./losetup -d "${loop_device}"
    rm -rf /tmp/mount_core "${CORE_IMG_PATH}"
    
    # Add localhost to /etc/hosts
    echo "127.0.0.1 localhost" >> "${ROOTFS_DIR}/etc/hosts"

    # NOTE: Ubuntu Core does not use apt-get. You should remove the chroot call below.
    # It relies on 'snap' for package management.
    # The following line is commented out as it will fail on Ubuntu Core.
    # chroot ${ROOTFS_DIR} /bin/bash -c "apt-get update && apt-get install -y sudo"
    
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac
if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir $ROOTFS_DIR/usr/local/bin -p
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/Quanvm0501alt1/freeroot/main/proot-${ARCH}"
  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm $ROOTFS_DIR/usr/local/bin/proot -rf
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/Quanvm0501alt1/freeroot/main/proot-${ARCH}"
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
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
