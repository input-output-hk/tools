{ config, lib, pkgs, ... }:
{
  users.users.angerman = {
    isNormalUser = true;
    home = "/home/angerman";
    description = "Moritz Angermann";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7HhR8q5Hx8pMokhgF3MJFVwGPnQHebxJbTJ0IccbNQD/kuXPfWNPaocF3NQAgcJ4c/SIcHHS+iXH0SP2vhXY8SvqgrA8aiwCMEfC1Bcj0EUJxwJ/z2XohmECXqQFMp7e7Y9gbSdiltJPvhxB8VX/TeGWum/bBIMvVOIUX6qOywzxFEUA0y0zRiFUdMj1g4takEwFi4OyMqU8tPJw+s8VnWmMt/Tgeden5gO8rWEGKeWeozTYMX4zZw/fA6Au4R5QvcLsEgG12gR5nNnCHOB11OkiiweoLRY3cZx5JDk/eipn8jWMGPxzHBsy/vJR7PiJ591f2U1dbsMXbnNeTDlInChKgDsbrgAsvccmHC8TMucvdhjxnowwNS7Ay696fD2Q7Spel36kE+nWGNuygtLY6+RnY1LdrCkdyAZvU7D/WW7KLXUnCBW90+l/qJTb0p6UD56CcpCuZkAZAqUX4jIVeAbO5AOpt/AsC2bnM/8D3Nql/+MNHOqq4tDNTCE8hz0uBx39e2QlIwq16W5go3zaAYq1AWPGvuq3FBPAyo74d3BxA7fIU3wNjWuYZy7Q5mdwVTrf0Rdvpl0ldF4nm3wUW1kRSToT1FwIsKBfEVW3vB70IPMQfbngjLG160L7HaFzkVK1he5kcWpXdTi2id9/3GAHD7/lEaYZorJL+7Xz+vQ== angerman@rmbp13" ];
  };

  users.users.hamish = {
    isNormalUser = true;
    home = "/home/hamish";
    description = "Hamish Mackenzie";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAqpSYY0nJIaKaH1/HiwQzwMiqde6RF8T6FOEaMFb86hc76TjBODpP+klS+rpVge4a2Ew/2z3KYz+A2rAWRl1u3FBYuPua+B44xKeEz9+TWdUhkDu8Jubpy0oY5YYqR4MFV0UYoag+/2LD/Kcok82sSDMkccAoAak/4B840sUUD8E= hamish@hamish-mackenzies-computer-2.local" ];
  };

  users.users.josh = {
    isNormalUser = true;
    home = "/home/josh";
    description = "Josh Meredith";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCW1cXh288++n0flJ+dGc7/V8OQCEHzcRrPC09ZaZQN9qCY1ZQRe8h/4Ceo0TwVrXbf87Ja9IbTlTCGcWwEWaWQfSLdjsmTeN/DK8GiunlyUk4AJLiiir9piKCz7QOObhgNinYdH2zMcGDeBxDMuHbiiYFa5XsZO/BJhIgce302XcR7OHXSVnKc8h57LWMLWds3iUyl1x8OmviJZOZ1rAMCvpBo6O9nMSPjSFGPx2SICoHbCs2pJY3vLfcG88GDiwvQIbrSZE1T1cK716nYGkZjIVQVZmYC4XN/ZDuwvZntdsTzXwD6J0WRV0yeabhu2V7T2m2fKZNcs0ci7isa9UKJ joshmeredith2008@gmail.com" ];
  };

  users.users.luite = {
    isNormalUser = true;
    home = "/home/luite";
    description = "Luite Stegeman";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5w8VjXqqZ37vQ5CIiAksBydqbyde/rW1wW00wB6PLhIst0EjQjyFNmAchtD+nbZG0yqmSCTRlbx/gn5n/G8gL6swm8BhPPBwWu1LDBmpu1imiMZ27jKr+zPYehlcxP9EVPAbJw5+FpZi1hpsubeAMPF8t7mlFF7hBrpXgiVTTUUKdFpOtxk6isZs+yvrkS0zs9g+DmHuj9nC7Ww4k0fdV776xpXXSwbLNsLCQlOp353q3MBUFPy4Ckh2ES+3Tv6S7MTevJxoYlY/x6AIse78kQX+8afWPe1OcaOWzgIcpk2JmQcPURZH3UDI757QRVT8+Pw6TzgUQA3P7fWjRYrr/ stegeman@gmail.com" ];
  };

  users.users.rodney = {
    isNormalUser = true;
    home = "/home/rodney";
    description = "Rodney Lorrimar";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAX/rqYt9+PIB3HLORPK5vojRzC81WSP8qANpITUyxhQ rodney@blue" ];
  };
}
