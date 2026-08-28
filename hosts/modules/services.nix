{pkgs, ... }:

{
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
}