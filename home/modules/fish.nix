{ repo, host, ... }:

{
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
      homepkgs = "$EDITOR ${repo}/home/modules/pkgs.nix";
      commonpkgs = "$EDITOR ${repo}/hosts/modules/pkgs.nix";
    };
  };
}
