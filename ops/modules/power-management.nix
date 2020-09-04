{ lib, ... }:
{
    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}