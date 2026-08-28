# Конфиги, которые меняются редко: кладутся через /nix/store, применяются
# пересборкой (rebuild). Про разницу с живыми симлинками — в home/roman.nix.

{ ... }:

{
  #############################################################
  ## Уведомления, меню приложений, fastfetch, cava
  #############################################################
  xdg.configFile."mako/config".source             = ../files/mako/config;
  xdg.configFile."wofi/config".source             = ../files/wofi/config;
  xdg.configFile."wofi/style.css".source          = ../files/wofi/style.css;
  xdg.configFile."fastfetch/config.jsonc".source  = ../files/fastfetch/config.jsonc;
  xdg.configFile."fastfetch/hypr_chan.png".source = ../files/fastfetch/hypr_chan.png;
  xdg.configFile."cava/config".source             = ../files/cava/config;
}
