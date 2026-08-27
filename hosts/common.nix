# Общая часть системы: всё, что одинаково на ноутбуке и на стационарном
# компьютере. Железозависимое лежит рядом, в hosts/<хост>/configuration.nix:
#
#   hosts/nixos/    — Huawei MateBook (Intel Alder Lake + встроенная графика)
#   hosts/desktop/  — стационарный (AMD + видеокарта AMD)
#
# Правь этот файл, если изменение должно появиться на обеих машинах.
# Применить: rebuild (= sudo nixos-rebuild switch --flake ~/nixos-config)

{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../sotavpn-nix/module.nix ];

  #############################################################
  ## Загрузчик и ядро
  #############################################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 15;   # не забивать /boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Прошивки для WiFi/Bluetooth, а на AMD — ещё и для самой видеокарты
  hardware.enableRedistributableFirmware = true;

  #############################################################
  ## Сеть
  #############################################################
  networking.networkmanager.enable = true;

  # sotavpn — не трогать
  services.sotavpn.enable = true;
  services.sotavpn.package = pkgs.callPackage ../sotavpn-nix/package.nix { };

  #############################################################
  ## Локаль и время
  #############################################################
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };
  console.keyMap = "us";

  #############################################################
  ## Японский ввод: fcitx5 + mozc
  #############################################################
  # en/ru по-прежнему переключает сам Hyprland (Alt+Shift) — это не тронуто.
  # Японский устроен иначе: иероглифы не лежат на клавишах, их набирают
  # латиницей, а движок mozc превращает ромадзи в кану и предлагает кандзи.
  # Поэтому отдельная xkb-раскладка "jp" не нужна — она описывает физическую
  # японскую клавиатуру, а не сам ввод. Ctrl+Space включает и выключает mozc.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;                  # ввод через родной wayland-протокол
      addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
      settings = {
        # Это только стартовый набор: при первом же изменении fcitx5 заведёт
        # свои файлы в ~/.config/fcitx5 и дальше читает уже их, а не эти.
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0" = { Name = "keyboard-us"; Layout = ""; };
          "Groups/0/Items/1" = { Name = "mozc";        Layout = ""; };
          GroupOrder = { "0" = "Default"; };
        };
        globalOptions = {
          Hotkey = { EnumerateWithTriggerKeys = "True"; };
          "Hotkey/TriggerKeys" = { "0" = "Control+space"; };
          "Hotkey/EnumerateForwardKeys" = { "0" = "Control+space"; };
          Behavior = { ActiveByDefault = "False"; };
        };
      };
    };
  };

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

  #############################################################
  ## Fish-shell терминала
  #############################################################
  programs.fish.enable = true;
  users.users.roman.shell = pkgs.fish;

  #############################################################
  ## Nix: флейки, авто-сборка мусора, оптимизация стора
  #############################################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Каналов больше нет — система собирается из flake.lock. Эти две строки
  # подсовывают тот же самый запиненный nixpkgs всему остальному, чтобы
  # `nix-shell -p foo`, `nix run nixpkgs#foo` и `nix repl '<nixpkgs>'`
  # брали ровно те же пакеты, что и система, а не что-то со стороны.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  # Подсказка «команды нет, установи пакет X» требует канала и без него
  # работать не может. Выключено явно, чтобы не собирать её базу впустую.
  programs.command-not-found.enable = false;
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  #############################################################
  ## Hyprland / графическая сессия
  #############################################################
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";                       # Chrome/Electron нативно в Wayland
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Ice";
    HYPRCURSOR_SIZE = "24";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  security.polkit.enable = true;
  systemd.packages = [ pkgs.hyprpolkitagent ];  # user-юнит агента запроса прав
  security.pam.services.hyprlock = {};           # разблокировка экрана
  services.gnome.gnome-keyring.enable = true;    # хранилище паролей (нужно Chrome)
  programs.dconf.enable = true;

  # Экран входа
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --sessions /run/current-system/sw/share/wayland-sessions";
      user = "greeter";
    };
  };

  # Тема Qt-приложений в тон GTK
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  #############################################################
  ## Графика
  #############################################################
  # Драйверы (Intel или AMD) — в конфиге конкретного хоста,
  # в hardware.graphics.extraPackages.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;             # 32-битные игры в Steam
  };

  #############################################################
  ## Звук: PipeWire
  #############################################################
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  #############################################################
  ## Мышь: OpenRazer
  #############################################################
  hardware.openrazer = {
    enable = true;
    users = [ "roman" ];
  };

  #############################################################
  ## Bluetooth
  #############################################################
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;        # показывать заряд наушников
        FastConnectable = true;
      };
      Policy.AutoEnable = "true";
    };
  };
  services.blueman.enable = true;

  #############################################################
  ## Питание
  #############################################################
  # Три режима питания, переключаются на лету (как в GNOME):
  #   performance / balanced / power-saver
  # Панель: клик по иконке; клавиши: SUPER+ALT+P (цикл), SUPER+ALT+1..3.
  # TLP отключён намеренно: он привязывает настройки к «от сети / от батареи»
  # и не умеет переключаться по требованию. Включить оба сразу NixOS не даёт.
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  powerManagement.enable = true;

  #############################################################
  ## Файлы, печать, прочие сервисы
  #############################################################
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [ thunar-archive-plugin thunar-volman ];
  };
  services.gvfs.enable = true;      # сеть/корзина/автомонтирование в Thunar
  services.tumbler.enable = true;   # превью картинок
  services.udisks2.enable = true;   # флешки
  services.fwupd.enable = true;     # обновления прошивок

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;            # сетевые принтеры
  };

  zramSwap.enable = true;           # сжатый swap в RAM

  #############################################################
  ## Шрифты
  #############################################################
  fonts = {
    packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      nerd-fonts.jetbrains-mono
    ];
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Inter" "Noto Sans" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

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
    (callPackage ../pkgs/wallpaperengine-gui.nix { })

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

  #############################################################
  system.stateVersion = "26.05"; # НЕ МЕНЯТЬ
}
