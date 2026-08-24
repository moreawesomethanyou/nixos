# NixOS configuration — Huawei MateBook (Alder Lake) + Hyprland
# Системная часть. Правь, затем: sudo nixos-rebuild switch --flake ~/nixos-config#nixos
# (или просто `rebuild` — функция fish). Пользовательская часть: ../../home/roman.nix

{ config, pkgs, lib, inputs, ... }:

# Предел заряда батареи. Литий-ионные батареи заметно дольше живут, если не
# держать их постоянно заряженными под завязку — это ровно то, что делала
# галочка «беречь батарею» в GNOME.
#
#   batteryChargeEnd   — на этом уровне зарядка прекращается;
#   batteryChargeStart — опустившись ниже, батарея начинает заряжаться снова.
#
# Разрыв между числами нужен, чтобы ноут не подзаряжался каждые пару минут:
# постоянные короткие подзарядки сами по себе изнашивают батарею.
# Чтобы поменять предел — правь эти две цифры и делай sudo nixos-rebuild switch.
let
  batteryChargeStart = 70;
  batteryChargeEnd   = 80;

  # start пишем первым: ядро отвергнет end, если тот окажется меньше
  # текущего start (по умолчанию здесь 95/100).
  setBatteryLimit = ''
    bat=/sys/class/power_supply/BAT0
    if [ -e "$bat/charge_control_end_threshold" ]; then
      echo ${toString batteryChargeStart} > "$bat/charge_control_start_threshold"
      echo ${toString batteryChargeEnd}   > "$bat/charge_control_end_threshold"
    fi
  '';
in
{
  imports =
    [ ./hardware-configuration.nix
      ../../sotavpn-nix/module.nix
    ];

  #############################################################
  ## Загрузчик и ядро
  #############################################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 15;   # не забивать /boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Прошивки для Intel WiFi/Bluetooth
  hardware.enableRedistributableFirmware = true;

  # Устройство "Huawei WMI hotkeys" дублирует нажатия mute и клавиш громкости:
  # одно нажатие приходит и с обычной клавиатуры, и с него (через ~1.2 мс),
  # из-за чего действие срабатывало дважды и звук возвращался обратно.
  # Переназначить его клавиши нельзя — драйвер huawei-wmi отклоняет EVIOCSKEYCODE
  # ("Invalid argument" и для keycode 0, и для 240), поэтому убираем устройство
  # из поля зрения libinput целиком.
  # Яркость не страдает: её шлёт отдельное устройство Video Bus.
  # Ценой этого не работает клавиша отключения микрофона — её шлёт только оно.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="Huawei WMI hotkeys", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

  #############################################################
  ## Сеть
  #############################################################
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # sotavpn — не трогать
  services.sotavpn.enable = true;
  services.sotavpn.package = pkgs.callPackage ../../sotavpn-nix/package.nix { };

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
  ## Видео: аппаратное декодирование Intel
  #############################################################
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      libvdpau-va-gl
    ];
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
  ## Питание и батарея
  #############################################################
  # Три режима питания, переключаются на лету (как в GNOME):
  #   performance / balanced / power-saver
  # Панель: клик по иконке; клавиши: SUPER+ALT+P (цикл), SUPER+ALT+1..3.
  # TLP отключён намеренно: он привязывает настройки к «от сети / от батареи»
  # и не умеет переключаться по требованию. Включить оба сразу NixOS не даёт.
  # Профили здесь применяются через intel_pstate (energy_performance_preference),
  # потому что ACPI platform_profile этот ноутбук ядру не отдаёт.
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;                 # тротлинг Intel
  services.upower.enable = true;
  powerManagement.enable = true;

  # Ограничение заряда батареи — цифры и сам скрипт в начале файла.
  # Применяется при загрузке...
  systemd.services.battery-charge-limit = {
    description = "Ограничение заряда батареи";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = setBatteryLimit;
  };

  # ...и ещё раз после выхода из сна, на случай если контроллер забудет.
  powerManagement.resumeCommands = setBatteryLimit;

  # Крышка: закрыл — сон; закрыл при внешнем мониторе — ничего
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";

    # Короткое нажатие кнопки питания НЕ усыпляет.
    # Причина: эта же кнопка будит ноут из сна. Пока здесь было "suspend",
    # получалась петля — открыл крышку, экран чёрный, жмёшь кнопку, чтобы
    # разбудить, а logind вместо этого усыпляет обратно.
    # Выключение по-прежнему работает долгим удержанием (строка ниже).
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };

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
