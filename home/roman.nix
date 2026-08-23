# Home Manager: всё, что живёт в /home/roman.
#
# Два способа положить файл в ~/.config, они намеренно разные:
#
#   live "..."  — «живой» симлинк прямо на файл в этом репозитории.
#                 Правишь файл — изменения видны сразу, без пересборки
#                 (hyprctl reload / перезапуск waybar). Так сделаны конфиги,
#                 которые крутишь часто: hypr, waybar, kitty.
#
#   ./files/... — файл копируется в /nix/store, в ~/.config появляется
#                 симлинк только для чтения. Правится в репозитории,
#                 применяется через nixos-rebuild switch. Так сделано всё
#                 остальное — оно меняется редко.
#
# НЕ управляется отсюда намеренно (у этих программ своё изменяемое состояние,
# которое они переписывают сами): fcitx5, Chrome, Discord, Spotify, Steam, dconf.
{ config, pkgs, lib, ... }:

let
  repo = "${config.home.homeDirectory}/nixos-config";
  live = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
in
{
  home.username = "roman";
  home.homeDirectory = "/home/roman";

  # Не «версия Home Manager», а отметка о том, с какого релиза начата эта
  # конфигурация: по ней HM решает, применять ли к ней ломающие изменения
  # в дефолтах. Менять не нужно.
  home.stateVersion = "26.05";

  #############################################################
  ## Hyprland и его спутники — живые симлинки
  #############################################################
  xdg.configFile."hypr/hyprland.lua".source  = live "home/files/hypr/hyprland.lua";
  xdg.configFile."hypr/hypridle.conf".source = live "home/files/hypr/hypridle.conf";
  xdg.configFile."hypr/hyprlock.conf".source = live "home/files/hypr/hyprlock.conf";

  xdg.configFile."waybar/config.jsonc".source = live "home/files/waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source    = live "home/files/waybar/style.css";

  xdg.configFile."kitty/kitty.conf".source = live "home/files/kitty/kitty.conf";

  #############################################################
  ## Остальные конфиги — через store
  #############################################################
  xdg.configFile."mako/config".source           = ./files/mako/config;
  xdg.configFile."wofi/config".source           = ./files/wofi/config;
  xdg.configFile."wofi/style.css".source        = ./files/wofi/style.css;
  xdg.configFile."fastfetch/config.jsonc".source = ./files/fastfetch/config.jsonc;
  xdg.configFile."fastfetch/hypr_chan.png".source = ./files/fastfetch/hypr_chan.png;

  # Автозапуск GUI живых обоев. Под Hyprland этот каталог никто не читает
  # (обои запускает сам hyprland.lua), файл лежит для совместимости с DE,
  # которые его читают. Exec без пути в /nix/store — иначе он протухнет
  # после первой же сборки мусора.
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

  #############################################################
  ## Скрипты в ~/.local/bin
  #############################################################
  # На них ссылаются биндинги Hyprland, hypridle и модули waybar —
  # именно по пути ~/.local/bin, поэтому кладём их туда же.
  home.file = lib.genAttrs
    (map (n: ".local/bin/${n}")
      [ "hypr-display" "hypr-dpms" "hypr-lid" "lang-indicator" "lang-poke" "power-mode" ])
    (name: {
      source = ./bin + "/${baseNameOf name}";
      executable = true;
    });

  #############################################################
  ## Fish
  #############################################################
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting ""
      fastfetch
    '';
    functions = {
      # Пересобрать систему из этого репозитория.
      rebuild = "sudo nixos-rebuild switch --flake ${repo}#nixos";
      # Обновить пакеты (правит flake.lock) и пересобрать.
      update = ''
        nix flake update --flake ${repo}; and sudo nixos-rebuild switch --flake ${repo}#nixos
      '';
      # Правка конфигов — теперь без sudo, файлы свои.
      nixconf  = "$EDITOR ${repo}/hosts/nixos/configuration.nix";
      homeconf = "$EDITOR ${repo}/home/roman.nix";
      hyprconf = "$EDITOR ${repo}/home/files/hypr/hyprland.lua";
      garbage  = "sudo nix-collect-garbage -d";
    };
  };

  home.sessionVariables.EDITOR = "vim";

  #############################################################
  ## Внешний вид GTK и курсор
  #############################################################
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    font = { name = "Inter"; size = 10; };
    theme = { name = "Adwaita-dark"; package = pkgs.gnome-themes-extra; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  #############################################################
  ## Чем открывать файлы и ссылки
  #############################################################
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html"                    = "google-chrome.desktop";
      "x-scheme-handler/http"        = "google-chrome.desktop";
      "x-scheme-handler/https"       = "google-chrome.desktop";
      "x-scheme-handler/about"       = "google-chrome.desktop";
      "x-scheme-handler/unknown"     = "google-chrome.desktop";
      "x-scheme-handler/claude-cli"  = "claude-code-url-handler.desktop";
      "text/markdown"                = "org.gnome.Papers.desktop";
      "x-scheme-handler/tg"          = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite"     = "org.telegram.desktop.desktop";
    };
    associations.added = {
      "text/markdown"            = [ "vim.desktop" "org.gnome.Papers.desktop" ];
      "x-scheme-handler/tg"      = [ "org.telegram.desktop.desktop" ];
      "x-scheme-handler/tonsite" = [ "org.telegram.desktop.desktop" ];
    };
  };

  # Пакеты только для пользователя ставятся сюда; системные — в
  # environment.systemPackages в hosts/nixos/configuration.nix.
  home.packages = [ ];
}
