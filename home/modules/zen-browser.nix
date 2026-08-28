{ inputs, ... }:

{
  #############################################################
  ## Zen-browser
  #############################################################
  # Сам модуль приходит из отдельного флейка (см. inputs в flake.nix).
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = false;
  };
}
