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
#   * NVMe devices aren't supported for booting (those require EFI boot)
# * We set a custom `configuration.nix` so that we can connect to the machine afterwards,
#   inspired by https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Online
# * This server has 2 HDDs.
#   We put everything on RAID1.
#   Storage scheme: `partitions -> RAID -> LVM -> ext4`.
# * A root user with empty password is created, so that you can just login
#   as root and press enter when using the Hetzner spider KVM.
#   Of course that empty-password login isn't exposed to the Internet.
#   Change the password afterwards to avoid anyone with physical access
#   being able to login without any authentication.
# * The script reboots at the end.

ROOTDEVICE=/dev/nvme0n1
BOOTSIZE=256
BOOTTYPE=ext4
SWAPSIZE=$((64*1024))
POOLNAME=tank

set -eu
set -o pipefail

set -x

# install zfs
# zpool --help || echo y | /root/.oldroot/nfs/tools/install_zfsonlinux.sh # zfsonlinux_install

umount /mnt/home /mnt/nix /mnt/boot /mnt || true
zpool import tank || true
zpool destroy tank || true
swapoff ${ROOTDEVICE}p3 || true

# Inspect existing disks
lsblk

# This is essentially what `justdoit` from the kexec install does.
wipefs -a ${ROOTDEVICE}
dd if=/dev/zero of=${ROOTDEVICE} bs=512 count=10000
# sfdisk ${ROOTDEVICE} <<EOF
# label: gpt
# device: ${ROOTDEVICE}
# unit: sectors
# 1 : size=$((2048 * $BOOTSIZE)), type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
# 4 : size=4096, type=21686148-6449-6E6F-744E-656564454649
# 2 : size=$((2048 * $SWAPSIZE)), type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
# 3 : type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
# EOF

parted --script --align optimal /dev/nvme0n1 -- \
mklabel gpt \
mkpart 'BIOS-boot-partition' ext3 1MB 2MB set 1 bios_grub on \
mkpart 'boot' ext3 2MB 257MB \
mkpart 'swap' linux-swap 257MB 128GB \
mkpart 'data' ext3 128GB '100%'

partprobe

export ROOT_DEVICE=${ROOTDEVICE}p4
export SWAP_DEVICE=${ROOTDEVICE}p3
export NIXOS_BOOT=${ROOTDEVICE}p2

mkdir -p /mnt

mkfs.ext3 $NIXOS_BOOT -L NIXOS_BOOT
mkfs.ext3 $ROOT_DEVICE -L NIXOS_ROOT
mkswap $SWAP_DEVICE -L NIXOS_SWAP

# zpool create -o ashift=12 -o altroot=/mnt ${POOLNAME} $ROOT_DEVICE
# zfs create -o mountpoint=legacy ${POOLNAME}/root
# zfs create -o mountpoint=legacy ${POOLNAME}/home
# zfs create -o mountpoint=legacy ${POOLNAME}/nix

swapon $SWAP_DEVICE

# NixOS pre-installation mounts
# Mount target root partition
mount $ROOT_DEVICE /mnt/
mkdir -p /mnt/boot
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

# On the Hetzner rescue mode, the default Internet interface is called `eth0`.
# Find what its name will be under NixOS, which uses stable interface names.
# See https://major.io/2015/08/21/understanding-systemds-predictable-network-device-names/#comment-545626
INTERFACE=$(udevadm info -e | grep -A 13 ^P.*eth0 | grep -o -E 'ID_NET_NAME_PATH=\w+' | cut -d= -f2)
echo "Determined INTERFACE as $INTERFACE"

# Determine our Internet IP by checking which route would be taken.
# The `ip route get` output on Hetzner looks like:
#   # ip route get 8.8.8.8
#   8.8.8.8 via 1.2.3.161 dev eth0 src 1.2.3.165
#      cache
IP_V4=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
echo "Determined IP_V4 as $IP_V4"

# Determine Internet IPv6 by checking route, and using ::1
# (because Hetzner rescue mode uses ::2 by default).
# The `ip -6 route get` output on Hetzner looks like:
#   # ip -6 route get 2001:4860:4860:0:0:0:0:8888
#   2001:4860:4860::8888 via fe80::1 dev eth0 src 2a01:4f8:151:62aa::2 metric 1024  pref medium
IP_V6="$(ip route get 2001:4860:4860:0:0:0:0:8888 | head -1 | cut -d' ' -f7 | cut -d: -f1-4)::1"
echo "Determined IP_V6 as $IP_V6"


# From https://stackoverflow.com/questions/1204629/how-do-i-get-the-default-gateway-in-linux-given-the-destination/15973156#15973156
read _ _ DEFAULT_GATEWAY _ < <(ip route list match 0/0); echo "$DEFAULT_GATEWAY"
echo "Determined DEFAULT_GATEWAY as $DEFAULT_GATEWAY"

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

  # # Network (Hetzner uses static IP assignments, and we don't use HDCP here)
  # networking.useDHCP = false;
  # networking.interfaces."$INTERFACE".ipv4.addresses = [
  #   {
  #     address = "$IP_V4";
  #     prefixLength = 24;
  #   }
  # ];
  # networking.interfaces."$INTERFACE".ipv6.addresses = [
  #   {
  #     address = "$IP_V6";
  #     prefixLength = 64;
  #   }
  # ];
  # networking.defaultGateway = "$DEFAULT_GATEWAY";
  # networking.defaultGateway6 = { address = "fe80::1"; interface = "$INTERFACE"; };
  # networking.nameservers = [ "8.8.8.8" ];

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

umount /mnt/boot /mnt
swapoff $SWAP_DEVICE

reboot
