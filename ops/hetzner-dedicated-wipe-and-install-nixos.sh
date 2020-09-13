#!/usr/bin/env bash

# Installs NixOS on a Hetzner server, wiping the server.
#
# This is for a specific server configuration; adjust where needed.
#
# Prerequisites:
#   * Update the script to adjust SSH pubkeys, hostname, NixOS version etc.
#
# Usage:
#     ssh root@YOUR_SERVERS_IP "$(< hetzner-dedicated-wipe-and-install-nixos.sh)"
#
# When the script is done, make sure to boot the server from HD, not rescue mode again.

# Explanations:
#
# * Adapted from https://gist.github.com/nh2/78d1c65e33806e7728622dbe748c2b6a
# * Following largely https://nixos.org/nixos/manual/index.html#sec-installing-from-other-distro.
# * **Important:** We boot in legacy-BIOS mode, not UEFI, because that's what Hetzner uses.
# * We set a custom `configuration.nix` so that we can connect to the machine afterwards,
#   inspired by https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Online
# * This server has 2 HDDs (nvmes).
#   As this is just going to be a build agent, we don't care for raids.
#   We'll partition and install only on nvme0n1, later nvme1n1 can be
#   added to the zfs pool, simply with
#   $ zpool add tank /dev/nvme0n1
# * A root user with empty password is created, so that you can just login
#   as root and press enter when using the Hetzner spider KVM.
#   Of course that empty-password login isn't exposed to the Internet.
#   Change the password afterwards to avoid anyone with physical access
#   being able to login without any authentication.
# * The script reboots at the end.

ROOTDEVICE=/dev/nvme0n1
BOOTSIZE=256
BOOTTYPE=ext4
SWAPSIZE=$((128*1024))
POOLNAME=tank

set -eu
set -o pipefail

set -x

# install zfs
zpool --help || echo y | /root/.oldroot/nfs/tools/install_zfsonlinux.sh # zfsonlinux_install

umount /mnt/home /mnt/nix /mnt/boot /mnt || true
zpool destroy tank || true
swapoff ${ROOTDEVICE}p3 || true

# Inspect existing disks
lsblk

# This is essentially what `justdoit` from the kexec install does.
wipefs -a ${ROOTDEVICE}
dd if=/dev/zero of=${ROOTDEVICE} bs=512 count=10000

sfdisk ${ROOTDEVICE} <<EOF
label: gpt
device: ${ROOTDEVICE}
unit: sectors
1 : size=2048, type=21686148-6449-6E6F-744E-656564454649, name="BIOS-boot-partition"
2 : size=$((2048 * $BOOTSIZE)), type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="boot"
3 : size=$((2048 * $SWAPSIZE)), type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F, name="swap"
4 : type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="data"
EOF

export ROOT_DEVICE=${ROOTDEVICE}p4
export SWAP_DEVICE=${ROOTDEVICE}p3
export NIXOS_BOOT=${ROOTDEVICE}p2

mkdir -p /mnt

mkfs.ext3 $NIXOS_BOOT -L NIXOS_BOOT
mkswap $SWAP_DEVICE -L NIXOS_SWAP

zpool create -o ashift=12 -o altroot=/mnt ${POOLNAME} $ROOT_DEVICE
zfs create -o mountpoint=legacy ${POOLNAME}/root
zfs create -o mountpoint=legacy ${POOLNAME}/home
zfs create -o mountpoint=legacy ${POOLNAME}/nix

swapon $SWAP_DEVICE

# NixOS pre-installation mounts
# Mount target root partition

mount -t zfs ${POOLNAME}/root /mnt/
mkdir /mnt/{home,nix,boot}
mount -t zfs ${POOLNAME}/home /mnt/home/
mount -t zfs ${POOLNAME}/nix /mnt/nix/
mount $NIXOS_BOOT /mnt/boot/

# Installing nix

# Install nix requires `sudo`; the Hetzner rescue mode doesn't have it.
apt-get update
apt-get install -y sudo

# Allow installing nix as root, see
#   https://github.com/NixOS/nix/issues/936#issuecomment-475795730
mkdir -p /etc/nix
echo "build-users-group =" > /etc/nix/nix.conf

curl https://nixos.org/nix/install | sh
set +u +x # sourcing this may refer to unset variables that we have no control over
. $HOME/.nix-profile/etc/profile.d/nix.sh
set -u -x

nix-channel --add https://nixos.org/channels/nixos-19.03 nixpkgs
nix-channel --update

# Getting NixOS installation tools
nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"

nixos-generate-config --root /mnt

HOST_ID=$(echo $(head -c4 /dev/urandom | od -A none -t x4))
echo "Determined HOST_ID as $HOST_ID"

# Generate `configuration.nix`. Note that we splice in shell variables.
cat > /mnt/etc/nixos/configuration.nix <<EOF
{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  nixpkgs.localSystem.system = "x86_64-linux";

  # Use GRUB2 as the boot loader.
  # We don't use systemd-boot because Hetzner uses BIOS legacy boot.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "$ROOTDEVICE";
  };

  boot.zfs.devNodes = "/dev"; # fixes some virtualmachine issues
  boot.zfs.forceImportRoot = false;
  boot.zfs.forceImportAll = false;

  boot.supportedFilesystems = [ "zfs" ];
  # boot.kernelParams = [
  #   "boot.shell_on_fail"
  #   "panic=30" "boot.panic_on_fail" # reboot the machine upon fatal boot issues
  # ];

  networking.hostName = "loony-tools-agent";
  networking.hostId = "$HOST_ID"; # required for zfs use

  # Initial empty root password for easy login:
  users.users.root.initialHashedPassword = "";
  services.openssh.permitRootLogin = "prohibit-password";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7HhR8q5Hx8pMokhgF3MJFVwGPnQHebxJbTJ0IccbNQD/kuXPfWNPaocF3NQAgcJ4c/SIcHHS+iXH0SP2vhXY8SvqgrA8aiwCMEfC1Bcj0EUJxwJ/z2XohmECXqQFMp7e7Y9gbSdiltJPvhxB8VX/TeGWum/bBIMvVOIUX6qOywzxFEUA0y0zRiFUdMj1g4takEwFi4OyMqU8tPJw+s8VnWmMt/Tgeden5gO8rWEGKeWeozTYMX4zZw/fA6Au4R5QvcLsEgG12gR5nNnCHOB11OkiiweoLRY3cZx5JDk/eipn8jWMGPxzHBsy/vJR7PiJ591f2U1dbsMXbnNeTDlInChKgDsbrgAsvccmHC8TMucvdhjxnowwNS7Ay696fD2Q7Spel36kE+nWGNuygtLY6+RnY1LdrCkdyAZvU7D/WW7KLXUnCBW90+l/qJTb0p6UD56CcpCuZkAZAqUX4jIVeAbO5AOpt/AsC2bnM/8D3Nql/+MNHOqq4tDNTCE8hz0uBx39e2QlIwq16W5go3zaAYq1AWPGvuq3FBPAyo74d3BxA7fIU3wNjWuYZy7Q5mdwVTrf0Rdvpl0ldF4nm3wUW1kRSToT1FwIsKBfEVW3vB70IPMQfbngjLG160L7HaFzkVK1he5kcWpXdTi2id9/3GAHD7/lEaYZorJL+7Xz+vQ== angerman@rmbp13"
  ];

  services.openssh.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

}
EOF

cat /mnt/etc/nixos/hardware-configuration.nix

# Install NixOS
PATH="$PATH" NIX_PATH="$NIX_PATH" `which nixos-install` --no-root-passwd --root /mnt --max-jobs 40

umount /mnt/home /mnt/nix /mnt/boot /mnt
zpool export ${POOLNAME}
swapoff $SWAP_DEVICE

reboot
