{ pkgs, ... }:

{
  imports = [ ../../sotavpn-nix/module.nix ];
  #############################################################
  ## Сеть
  #############################################################
  networking.networkmanager.enable = true;

  # sotavpn — не трогать
  services.sotavpn.enable = true;
  services.sotavpn.package = pkgs.callPackage ../../sotavpn-nix/package.nix { };
}