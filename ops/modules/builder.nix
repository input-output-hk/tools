{ config, lib, pkgs, ... }:
{
  users.users.builder = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      ''command="nice -n20 nix-store --serve --write" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCx2oZoaoHu8YjD94qNp8BfST12FDvgevWloTXqjPQD+diOL1I6nC+nDT2hroAOIkShlM4O2OgbUArmTWc8nPTBUvRClYgjd7jPpVhkyTm9tsHlAFTpgv1n2GPIOK9e97dgU3ZB5phx58WcLVtBeCChFce4EM7oLMKYeo/4pggtal8rtqFjyViPrXncZLtYkIcaKFGBTUMeHi/S3GUiLIlp5VF34L21lPZCy5oZKf70kWWkT52coE4EyEx9fipp2vybMdB/qT4r9pMqa3mmf9IXwfIhoKadpMhPfyaYm+oxmddrSv6aDMjs89fB6cJGpLA5gQFfISQUD1DB8ufjW43v''
#      angerman
    ] ++ builtins.concatMap
        (info: map (key: ''command="nice -n20 nix-store --serve --write" ${key}'') info.openssh.authorizedKeys.keys)
        (builtins.attrValues
         (builtins.removeAttrs config.users.users [ "builder" "root" ]));
  };
  nix.trustedUsers = [ "builder" ];
}
