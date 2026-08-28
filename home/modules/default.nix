{ config, osConfig, ... }:

{
  imports = [
    ./hypr.nix
    ./waybar.nix
    ./kitty.nix
    ./configs.nix
    ./autostart.nix
    ./bin.nix
    ./fish.nix
    ./zen-browser.nix
    ./vscodium.nix
    ./gtk.nix
    ./mimeapps.nix
    ./env.nix
    ./pkgs.nix
  ];

  #############################################################
  ## Общее для всех модулей ниже
  #############################################################
  # Чтобы не повторять эти четыре определения в каждом файле, они раздаются
  # модулям как аргументы: модуль просто пишет { live, ... }: и пользуется.
  #
  #   repo     — путь к этому репозиторию в домашнем каталоге
  #   live     — «живой» симлинк на файл в репозитории (см. home/roman.nix)
  #   host     — имя хоста: nixos (ноутбук) или desktop (стационарный)
  #   isLaptop — true только на ноутбуке
  _module.args.repo = "${config.home.homeDirectory}/nixos-config";
  _module.args.live =
    path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/${path}";
  _module.args.host = osConfig.networking.hostName;
  _module.args.isLaptop = osConfig.networking.hostName == "nixos";
}
