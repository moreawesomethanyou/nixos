{ live, isLaptop, ... }:

let
  # Конфиг панели — единственное место, которое приходится разводить по
  # машинам: у неё JSON, а в нём нет «если». У ноутбука в панели есть батарея
  # и яркость, у десктопа их нет. Hyprland разбирается сам — там Lua, и он
  # смотрит, есть ли в системе батарея (см. home/files/hypr/hyprland.lua,
  # раздел «КАКАЯ ЭТО МАШИНА»).
  waybarConfig = if isLaptop
                 then "home/files/waybar/config.jsonc"
                 else "home/files/waybar/config-desktop.jsonc";
in
{
  #############################################################
  ## Панель — живые симлинки
  #############################################################
  xdg.configFile."waybar/config.jsonc".source = live waybarConfig;
  xdg.configFile."waybar/style.css".source    = live "home/files/waybar/style.css";
}
