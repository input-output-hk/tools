{ config, lib, pkgs, ... }:
{
  users.users.angerman = {
    isNormalUser = true;
    home = "/home/angerman";
    description = "Moritz Angermann";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7HhR8q5Hx8pMokhgF3MJFVwGPnQHebxJbTJ0IccbNQD/kuXPfWNPaocF3NQAgcJ4c/SIcHHS+iXH0SP2vhXY8SvqgrA8aiwCMEfC1Bcj0EUJxwJ/z2XohmECXqQFMp7e7Y9gbSdiltJPvhxB8VX/TeGWum/bBIMvVOIUX6qOywzxFEUA0y0zRiFUdMj1g4takEwFi4OyMqU8tPJw+s8VnWmMt/Tgeden5gO8rWEGKeWeozTYMX4zZw/fA6Au4R5QvcLsEgG12gR5nNnCHOB11OkiiweoLRY3cZx5JDk/eipn8jWMGPxzHBsy/vJR7PiJ591f2U1dbsMXbnNeTDlInChKgDsbrgAsvccmHC8TMucvdhjxnowwNS7Ay696fD2Q7Spel36kE+nWGNuygtLY6+RnY1LdrCkdyAZvU7D/WW7KLXUnCBW90+l/qJTb0p6UD56CcpCuZkAZAqUX4jIVeAbO5AOpt/AsC2bnM/8D3Nql/+MNHOqq4tDNTCE8hz0uBx39e2QlIwq16W5go3zaAYq1AWPGvuq3FBPAyo74d3BxA7fIU3wNjWuYZy7Q5mdwVTrf0Rdvpl0ldF4nm3wUW1kRSToT1FwIsKBfEVW3vB70IPMQfbngjLG160L7HaFzkVK1he5kcWpXdTi2id9/3GAHD7/lEaYZorJL+7Xz+vQ== angerman@rmbp13" ];
  };

  users.users.hamish = {
    isNormalUser = true;
    home = "/home/hamish";
    description = "Hamish Mackenzie";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAqpSYY0nJIaKaH1/HiwQzwMiqde6RF8T6FOEaMFb86hc76TjBODpP+klS+rpVge4a2Ew/2z3KYz+A2rAWRl1u3FBYuPua+B44xKeEz9+TWdUhkDu8Jubpy0oY5YYqR4MFV0UYoag+/2LD/Kcok82sSDMkccAoAak/4B840sUUD8E= hamish@hamish-mackenzies-computer-2.local" ];
  };

  users.users.josh = {
    isNormalUser = true;
    home = "/home/josh";
    description = "Josh Meredith";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCW1cXh288++n0flJ+dGc7/V8OQCEHzcRrPC09ZaZQN9qCY1ZQRe8h/4Ceo0TwVrXbf87Ja9IbTlTCGcWwEWaWQfSLdjsmTeN/DK8GiunlyUk4AJLiiir9piKCz7QOObhgNinYdH2zMcGDeBxDMuHbiiYFa5XsZO/BJhIgce302XcR7OHXSVnKc8h57LWMLWds3iUyl1x8OmviJZOZ1rAMCvpBo6O9nMSPjSFGPx2SICoHbCs2pJY3vLfcG88GDiwvQIbrSZE1T1cK716nYGkZjIVQVZmYC4XN/ZDuwvZntdsTzXwD6J0WRV0yeabhu2V7T2m2fKZNcs0ci7isa9UKJ joshmeredith2008@gmail.com" ];
  };

  users.users.luite = {
    isNormalUser = true;
    home = "/home/luite";
    description = "Luite Stegeman";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5w8VjXqqZ37vQ5CIiAksBydqbyde/rW1wW00wB6PLhIst0EjQjyFNmAchtD+nbZG0yqmSCTRlbx/gn5n/G8gL6swm8BhPPBwWu1LDBmpu1imiMZ27jKr+zPYehlcxP9EVPAbJw5+FpZi1hpsubeAMPF8t7mlFF7hBrpXgiVTTUUKdFpOtxk6isZs+yvrkS0zs9g+DmHuj9nC7Ww4k0fdV776xpXXSwbLNsLCQlOp353q3MBUFPy4Ckh2ES+3Tv6S7MTevJxoYlY/x6AIse78kQX+8afWPe1OcaOWzgIcpk2JmQcPURZH3UDI757QRVT8+Pw6TzgUQA3P7fWjRYrr/ stegeman@gmail.com" ];
  };

  users.users.hsyl20 = {
    isNormalUser = true;
    home = "/home/hsyl20";
    description = "Sylvain Henry";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDE5PkhVIzJvhRqxZzCjHQQTV6v040uml8Fiy/W9HfDiuovjZT2QWgfSr+y63YnpFUXYJrWUekWAJh5BwWOJtZN43EXb7LlXluYsykOUbcRglzpD82w6BuLuI3lgcpKwDJWgzU+siqo8NuiZDKiYSho2A97uebJWXFyWBkmXqtcpOe70qygVqviB6+0WYjuOmDoa8tcmGjdY2Qq+IkwalX2mrlqfUosCdvzptexeF4vGshjce8v9G7Kyw3zpbqqZR6oAsNH5OcLZI5GYvzdXvWZobqV1TVpnr3zmavLwwZhULY/3lqbzKiHjheSQvMOmFnKhyzhFlNkNIFm+zLAZcKmZF77Wy/6crMniD3fQthoqhPz/pYW2PFSYlLUaQyHrOgbKDB96CIo9JwxqRuc8dNvk/Vo5ZGE0ki8Iyu6niAU+x4DZ3Go5Cma3A0LZWD61O1h44cpDTTfgygYyCdnlw5K274EUzj8rMYsiVoWkcvh1fDC5YTWyxkUnOAoCQIjfrWPM97ascT/AQkBNjGTo/45+Ui7fhor4PH88aeGzPAHCZOdDP4f4N5ubPJE7BiC9BIHdxvvUwGHcs8V4p4JNi3IPvp6VntMYQ89yroU18sbuiVbNNKJK2NIKNhn+0ex1+Tq/Z7OeJETfHrxTUNUlR/7niwUCxYfJRGV15wM0cZReQ== sylvain.henry@iohk.io" ];
  };

  users.users.rodney = {
    isNormalUser = true;
    home = "/home/rodney";
    description = "Rodney Lorrimar";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAX/rqYt9+PIB3HLORPK5vojRzC81WSP8qANpITUyxhQ rodney@blue" ];
  };

  users.users.erikd = {
    isNormalUser = true;
    home = "/home/erikd";
    description = "Erik de Castro Lopo";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3EF0zDleld74EJhRFnDZH/CLPAI4Udsro5D5d9pMGA erikd@ada" ];
  };

  users.users.reactormonk = {
    isNormalUser = true;
    home = "/home/reactormonk";
    description = "Simon Hafner";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCj+0FtX7z6h/vVr476ekHsvioMeC3yCqpSiem1FK02C+dGmH5jd/UGFhnqTuJEB7yKWc2/G29/MEKpvBA+7Bpy1nhcUxE6eQL+6UDydB8Anz0JClECcogAKcckBkcYjjqbGwcP/Na7GP0jS+17aYZs7hSnnEgxIAGrxkCzWdje3dzUFrrVPuY1y4ltl5u/7i693Y5Cx8ei09L+18VHovmhlKrRIYoKA09D1ivZG6fv45WZAQCZW544h/8IqYOBQdSVT0fizOTdXisKo+zhnkV8InyzrVGSIgpejbS1cCAhdnFNzFPLohSmDXrAJPUvo5+vcEaz3siyKZVDUfwiGI4L tass@exia" ];
  };

  users.users.michaelpj = {
    isNormalUser = true;
    home = "/home/michaelpj";
    description = "Michael Peyton Jones";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3Xw/OJSqbbcKoG2/FtiGrLlLcgB6gWb0OEN3fIfYMTMtMiDpknDliNoRdDZl794FicFmgvvdLtG40ITrxfxxxufP15uD/0yXLL+pA3IavKmV7g5Xn35cKtVEoIm/fIiWh1oLmHgyrC49Op19OxilCSsrJhaJjIE2cj3KFqCOsTMG/p2UjSdrYVSns7PxCUHTMZ/5uF/n9K7nbcHTvYUMBWnsBSaHRmdTDHQWeIuEIg730kIeFjqCNydZX/XeDjXoBAsJuH3YzRvjvneXyZqw4agS1cXQEye843/8SB76PgeSqGU6xxSaXegVE35JqWpO0tlfQ6Rx4aDq8fD23mJYGl3JTuARgVizk7Ot3I2kBEzn9Bm8VUgV+NW16oQjfYKjB0045G6+94e+N9bJKglHxrvZyMVjhGgWY7fqSblRckvYUkpK0C8NB5473J3kH+a59L4jcoelqU0rHe44x0t/RNHkf1gJ5kSHyz5+bmDDSa1pkNxcoxDWvP8c+t9ckFuYSt+7pPLBN99S1Ue3X5Vf/a5MYfel1n9fip/WL6K26RYmsifpYkqJRdpX2/1V13q+ZX7NrLNomvP4zQRpYCUK997K3hLUAVhhftLh/j78gNbmHcBdHVYiYSVAsw9WSf1FPnUPi42Bjx4vAc2WDoHFEmXSGeH/+b/jVvoNKXPTmrQ== michaelpj@gmail.com" ];
  };

  users.users.neil = {
    isNormalUser = true;
    home = "/home/neil";
    description = "Neil Davies";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLur/c3K8lPo9UqYI+QeSXmUHlmlXoVmBY3Y1ftQV7wVFCZkCv6OZbC2ZLj5RCwx0oc6B3zebz9oI0qhdZsRrA7tKwC4v9PGdKu9mT8pLzsIB1leGYbd6j5S9CpMQ0cdaInnz5/ob8JiR8yju9mw89k+fbf7lDKoRIYCjFCwCJS3lzx34EQqD2c0+Hqh2qhjg6kmpaXg1trIUbOzDUA+3Lkg6yzaMLPgcoURwNML/m0E8/JfObWvK52gztsNzQ32RtdCgiadPLh/FuO6onyAY+qV4h4CIiVF48buN/QoV01zc0oLOke6HUvelEPkVL88Jlu4ar+UAr3b4jd8vKt9az neil" ];
  };

  users.users.karl = {
    isNormalUser = true;
    home = "/home/karl";
    description = "Karl Knutsson";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDNrO0NpTr5Rp8R/lq3a+nzBPUWkWdxzMof8d8QTBr63sL/uY59iNAsJuvl2zeIHrBAdKPaVETHn1Irj86hIbJJTt96rmXqpYNfK9dO7v8nzUV6c9EvYtGhMLJmIlZ8BNM1EV3INAOs1CmJL1Piz0aR2dFINkoqA2v1L6G9dMVrVyqTIr/9yN927/YwhxRsEnZz/5B+/YzMpewZqDj3onVTP0PpkHFr3EEmyWGVtAB+AoqOaXagc4w97hot1qvCu6vAE0lFDJfRZH1t/218JyMrZCKV8s5L4cxoYmZpsZlYnhyRwuU2cbD7h/yhjJL1GhwfMNwyMUyUpHi/C2IaZqXDir/xXk/4Uz/lx0qSFipBnGw576Li8Eid4THM6elllPl7zVFFwwaRYyehVof8+tWsUsB5aJZh0nmNOqdU1q8x+S056akwCQcXPVHtd15juvJW63nMY73+mYK9CsGX109nosugr4OluivLXdBGMo6fZ7m7+s/F2FFuvDGix8lzv+P1mrqM+zXdYOu775j+OX3JuAaSq2fjs5dE5TnW+DiFZ/ax+55f8ntk0qnN9DDi7btHnpLFfq9W/YH7xFR0xBbx7qA9UJ6y55guItGDA26PMaTCoVNyBgaN6q/9IWWMQShbCcvGGJxzBvLFcpk9Hl61GuXkEWVrNPhhtwLiZGTuQ== karknu@iohk" ];
  };
}
