{ config, pkgs, ... }:

{
  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/nvme0n1"; # or "nodev" for efi only

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7HhR8q5Hx8pMokhgF3MJFVwGPnQHebxJbTJ0IccbNQD/kuXPfWNPaocF3NQAgcJ4c/SIcHHS+iXH0SP2vhXY8SvqgrA8aiwCMEfC1Bcj0EUJxwJ/z2XohmECXqQFMp7e7Y9gbSdiltJPvhxB8VX/TeGWum/bBIMvVOIUX6qOywzxFEUA0y0zRiFUdMj1g4takEwFi4OyMqU8tPJw+s8VnWmMt/Tgeden5gO8rWEGKeWeozTYMX4zZw/fA6Au4R5QvcLsEgG12gR5nNnCHOB11OkiiweoLRY3cZx5JDk/eipn8jWMGPxzHBsy/vJR7PiJ591f2U1dbsMXbnNeTDlInChKgDsbrgAsvccmHC8TMucvdhjxnowwNS7Ay696fD2Q7Spel36kE+nWGNuygtLY6+RnY1LdrCkdyAZvU7D/WW7KLXUnCBW90+l/qJTb0p6UD56CcpCuZkAZAqUX4jIVeAbO5AOpt/AsC2bnM/8D3Nql/+MNHOqq4tDNTCE8hz0uBx39e2QlIwq16W5go3zaAYq1AWPGvuq3FBPAyo74d3BxA7fIU3wNjWuYZy7Q5mdwVTrf0Rdvpl0ldF4nm3wUW1kRSToT1FwIsKBfEVW3vB70IPMQfbngjLG160L7HaFzkVK1he5kcWpXdTi2id9/3GAHD7/lEaYZorJL+7Xz+vQ== angerman@rmbp13"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAX/rqYt9+PIB3HLORPK5vojRzC81WSP8qANpITUyxhQ rodney@blue"
    "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAqpSYY0nJIaKaH1/HiwQzwMiqde6RF8T6FOEaMFb86hc76TjBODpP+klS+rpVge4a2Ew/2z3KYz+A2rAWRl1u3FBYuPua+B44xKeEz9+TWdUhkDu8Jubpy0oY5YYqR4MFV0UYoag+/2LD/Kcok82sSDMkccAoAak/4B840sUUD8E= hamish@hamish-mackenzies-computer-2.local"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbtjKqNiaSVMBBSK4m97LXCBwhHMfJh9NBGBxDg+XYCLOHuuKw2MsHa4eMtRhnItELxhCAXZg0rdwZTlxLb6tzsVPXAVMrVniqfbG2qZpDPNElGdjkT0J5N1X1mOzmKymucJ1uHRDxTpalpg5d5wyGZgwVuXerep3nnv2xIIYcHWm5Hy/eG0pRw6XuQUeMc3xSU5ChqZPwWqhdILkYteKMgD8vxkfmYE9N/2fPgKRmujKQ5SA0HoJYKBXo29zGQY5r6nt3CzuIANFD3vG3323Znvt8dSRd1DiaZqKEDWSI43aZ9PX2whYEDyj+L/FvQa78Wn7pc8Nv2JOb7ur9io9t clever@amd-nixos"
  ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?
}
