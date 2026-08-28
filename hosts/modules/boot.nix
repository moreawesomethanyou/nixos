{ pkgs, ... }:

{
  #############################################################
  ## Загрузчик и ядро
  #############################################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 15;   # не забивать /boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Прошивки для WiFi/Bluetooth, а на AMD — ещё и для самой видеокарты
  hardware.enableRedistributableFirmware = true;
}