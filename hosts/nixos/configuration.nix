# NixOS — Huawei MateBook (Alder Lake) + Hyprland.
# Здесь только то, что относится к самому ноутбуку: батарея, крышка, экран,
# графика Intel, его собственные причуды. Всё общее с десктопом — в
# ../common.nix, пользовательская часть — в ../../home/roman.nix.
#
# Правь, затем: rebuild  (= sudo nixos-rebuild switch --flake ~/nixos-config)

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
      ../common.nix
    ];

  networking.hostName = "nixos";

  #############################################################
  ## Причуды железа
  #############################################################
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
  ## Видео: аппаратное декодирование Intel
  #############################################################
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    vpl-gpu-rt
    libvdpau-va-gl
  ];

  #############################################################
  ## Питание и батарея
  #############################################################
  # Профили питания (сам power-profiles-daemon включён в ../common.nix)
  # применяются здесь через intel_pstate (energy_performance_preference),
  # потому что ACPI platform_profile этот ноутбук ядру не отдаёт.
  services.thermald.enable = true;                 # тротлинг Intel

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
}
