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
  imports = [ ./modules ];

  #############################################################
  ## Fish-shell терминала
  #############################################################
  programs.fish.enable = true;
  users.users.roman.shell = pkgs.fish;

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
  system.stateVersion = "26.05"; # НЕ МЕНЯТЬ
}
