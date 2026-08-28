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
  imports = [ ../sotavpn-nix/module.nix
              ./commonmodules ];

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
  system.stateVersion = "26.05"; # НЕ МЕНЯТЬ
}
