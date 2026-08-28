# Hyprland и его спутники: сама оболочка, простой и блокировка экрана.
# Живые симлинки — правишь файл, изменения видны сразу, без пересборки
# (hyprctl reload).

{ live, ... }:

{
  #############################################################
  ## Hyprland, hypridle, hyprlock
  #############################################################
  xdg.configFile."hypr/hyprland.lua".source  = live "home/files/hypr/hyprland.lua";
  xdg.configFile."hypr/hypridle.conf".source = live "home/files/hypr/hypridle.conf";
  xdg.configFile."hypr/hyprlock.conf".source = live "home/files/hypr/hyprlock.conf";
}
