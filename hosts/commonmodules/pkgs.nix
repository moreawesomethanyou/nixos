{ pkgs, ... }:

{
  #############################################################
  ## Пакеты
  #############################################################
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;      # для Steam Remote Play
    dedicatedServer.openFirewall = true; # для хостинга dedicated-серверов
    localNetworkGameTransfers.openFirewall = true; # для локальной передачи игр
  };
  programs.gamemode.enable = true;


  environment.systemPackages = with pkgs; [
    # база
    vim wget curl git
    fastfetch btop htop
    unzip zip p7zip file tree ripgrep fd jq bat eza
    cava

    # браузер (остаётся Chrome) и терминал
    google-chrome
    kitty
    claude-code

    # оболочка Hyprland
    waybar             # панель
    wofi               # меню приложений
    mako libnotify     # уведомления

    # живые обои Wallpaper Engine: движок + GUI (GUI в nixpkgs нет, см. ./pkgs/)
    linux-wallpaperengine
    (callPackage ../../pkgs/wallpaperengine-gui.nix { })

    hyprlock hypridle  # блокировка/простой
    hyprpolkitagent    # диалоги прав доступа
    wlogout            # меню выключения

    # скриншоты и буфер обмена
    hyprshot grim slurp swappy
    wl-clipboard cliphist

    # железо: звук, яркость, сеть, мониторы
    brightnessctl playerctl
    pavucontrol pamixer pulseaudio
    networkmanagerapplet
    nwg-displays wdisplays
    polychromatic

    # приложения
    file-roller
    mpv imv loupe papers
    libreoffice-stable
    telegram-desktop
    anki
    discord
    spotify
    jetbrains.webstorm
    eog
    gedit

    # темы и утилиты
    adwaita-icon-theme papirus-icon-theme bibata-cursors gnome-themes-extra
    xdg-utils xdg-user-dirs
    glib               # gsettings
    wev
    socat              # индикатор языка слушает события Hyprland
    lm_sensors
  ];
}