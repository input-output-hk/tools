{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # utils
    wget
    vim
    psmisc
    which
    binutils
    dos2unix
    tmux
    file
    ncdu
    gnupg1compat

    # system tools
    htop
    iotop
    iftop
    lm_sensors
    dmidecode
    smartmontools
    sdparm
    hdparm
    lsof
    strace
    sysstat
    socat

    # for visual studio remote
    nodejs

    # nix-tools
    nix
    nix-prefetch-scripts
    haskellPackages.nix-derivation
    nix-diff
  ];

  # Set your time zone.
  time.timeZone = "UTC";

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
   22        # ssh
   80 443    # http(s)
  ];
  networking.firewall.allowedUDPPorts = [ ];
  networking.firewall.allowedUDPPortRanges = [
    # mosh mobile shell
    { from = 60000; to = 60999; }
  ];
  networking.firewall.allowPing = true;
  networking.firewall.trustedInterfaces = [ "lo" "docker0" ];

  programs.mosh.enable = true;
  # services.udev.extraRules = ''
  #   # rename eno1 to eth0
  #   ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="b4:2e:99:45:36:a2", NAME="eth0"
  # '';

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "without-password";
    passwordAuthentication = false;
  };

  # NTP time sync.
  services.timesyncd.enable = true;
  services.timesyncd.extraConfig = ''
    PollIntervalMinSec=16
    PollIntervalMaxSec=32
  '';

  # Enable docker
  virtualisation.docker.enable = true;

  # Keep a reference to nixpkgs in /run/current-system/nixpkgs
  system.extraSystemBuilderCmds = ''
    ln -sv ${pkgs.path} $out/nixpkgs
  '';

  nix = {
    nixPath = [ "nixpkgs=/run/current-system/nixpkgs" ];
    useSandbox = true;
    trustedUsers = [ "root" "@wheel" ];
    binaryCaches = [
      "https://cache.nixos.org"
    ];
    binaryCachePublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    requireSignedBinaryCaches = true;
    extraOptions = ''
      builders-use-substitutes = true

      # Prevents build outputs of a .drv being GC'd
      # if the .drv is a GC root.
      keep-outputs = true
      keep-derivations = true

      min-free = ${toString (1024*1024*1024*20)}
      max-free = ${toString (1024*1024*1024*40)}
    '';
  };
}
