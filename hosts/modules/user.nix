{pkgs, ...}:

{
  #############################################################
  ## Пользователь
  #############################################################
  users.users."roman" = {
    isNormalUser = true;
    description = "roman";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "lp" "scanner" ];
    packages = with pkgs; [];
  };
  security.sudo.wheelNeedsPassword = false;
  nixpkgs.config.allowUnfree = true;
}