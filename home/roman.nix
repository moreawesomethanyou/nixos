# Home Manager: всё, что живёт в /home/roman. Один файл на обе машины.
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
{ config, pkgs, lib, inputs, osConfig, ... }:

let
  repo = "${config.home.homeDirectory}/nixos-config";
  live = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";

  # Конфиг общий для двух машин, и почти всё на них одинаково. Различия,
  # которые нельзя разрешить на месте, разведены по имени хоста:
  #   nixos   — ноутбук Huawei MateBook
  #   desktop — стационарный компьютер
  # Отсюда берётся только панель: у неё JSON, а в нём нет «если». Hyprland
  # разбирается сам — там Lua, и он смотрит, есть ли в системе батарея
  # (см. home/files/hypr/hyprland.lua, раздел «КАКАЯ ЭТО МАШИНА»).
  host = osConfig.networking.hostName;
  isLaptop = host == "nixos";

  waybarConfig = if isLaptop
                 then "home/files/waybar/config.jsonc"
                 else "home/files/waybar/config-desktop.jsonc";
in
{
  home.username = "roman";
  home.homeDirectory = "/home/roman";
  
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

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

  # Панель: у ноутбука в ней батарея и яркость, у десктопа их нет.
  xdg.configFile."waybar/config.jsonc".source = live waybarConfig;
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
  xdg.configFile."cava/config".source             = ./files/cava/config;

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
      # Пересобрать систему из этого репозитория. Без «#имя»: тогда
      # nixos-rebuild берёт конфигурацию по имени хоста, и одна и та же
      # команда работает и на ноутбуке, и на десктопе.
      rebuild = "sudo nixos-rebuild switch --flake ${repo}";
      # Обновить пакеты (правит flake.lock) и пересобрать.
      update = ''
        nix flake update --flake ${repo}; and sudo nixos-rebuild switch --flake ${repo}
      '';
      # Правка конфигов — теперь без sudo, файлы свои.
      nixconf  = "$EDITOR ${repo}/hosts/${host}/configuration.nix";
      # Общая для обеих машин часть системы.
      commonconf = "$EDITOR ${repo}/hosts/common.nix";
      homeconf = "$EDITOR ${repo}/home/roman.nix";
      hyprconf = "$EDITOR ${repo}/home/files/hypr/hyprland.lua";
      garbage  = "sudo nix-collect-garbage -d";
    };
  };
  #############################################################
  ## Zen-browser
  #############################################################
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = false;
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
      "x-scheme-handler/tg"          = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite"     = "org.telegram.desktop.desktop";
      "image/jpeg" = "org.gnome.eog.desktop";
      "image/png" = "org.gnome.eog.desktop";
      "image/gif" = "org.gnome.eog.desktop";
      "image/webp" = "org.gnome.eog.desktop";
      "image/bmp" = "org.gnome.eog.desktop";
      "image/tiff" = "org.gnome.eog.desktop";
      "image/svg+xml" = "org.gnome.eog.desktop";
      "image/x-icon" = "org.gnome.eog.desktop";

      "text/plain" = [ "org.gnome.gedit.desktop" ];
      "text/markdown" = [ "org.gnome.gedit.desktop" ];
      "text/x-log" = [ "org.gnome.gedit.desktop" ];
      "application/x-shellscript" = [ "org.gnome.gedit.desktop" ];
      "application/json" = [ "org.gnome.gedit.desktop" ];
      "application/xml" = [ "org.gnome.gedit.desktop" ];
    };
    associations.added = {
      "x-scheme-handler/tg"      = [ "org.telegram.desktop.desktop" ];
      "x-scheme-handler/tonsite" = [ "org.telegram.desktop.desktop" ];
      "image/jpeg" = [ "org.gnome.eog.desktop" ];
      "image/png" = [ "org.gnome.eog.desktop" ];
      "text/plain" = [ "org.gnome.gedit.desktop" ];
    };
  };

  # Пакеты только для пользователя ставятся сюда; системные — в
  # environment.systemPackages в hosts/nixos/configuration.nix.
  home.packages = [];
}
