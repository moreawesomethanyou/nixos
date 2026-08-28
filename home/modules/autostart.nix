{ ... }:

{
  #############################################################
  ## Автозапуск GUI живых обоев
  #############################################################
  # Под Hyprland этот каталог никто не читает (обои запускает сам
  # hyprland.lua), файл лежит для совместимости с DE, которые его читают.
  # Exec без пути в /nix/store — иначе он протухнет после первой же сборки
  # мусора.
  xdg.configFile."autostart/com.wallpaperengine.gui.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Linux Wallpaper Engine
    Comment=Wallpaper Engine for Linux (GUI)
    Exec=linux-wallpaperengine-gui --hidden
    Icon=com.wallpaperengine.gui
    Terminal=false
    Categories=Utility;Graphics;
    StartupNotify=true
    StartupWMClass=com.wallpaperengine.gui
    X-GNOME-Autostart-enabled=true
  '';
}
