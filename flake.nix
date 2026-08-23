# Флейк всей системы: NixOS + Home Manager для Huawei MateBook.
#
#   Пересобрать:      sudo nixos-rebuild switch --flake ~/nixos-config#nixos   (или: rebuild)
#   Обновить пакеты:  nix flake update --flake ~/nixos-config, затем пересобрать (или: update)
#   Откатиться:       sudo nixos-rebuild switch --rollback
#
# nixpkgs запинен на коммит, из которого система была собрана в момент
# перехода на флейки, — чтобы миграция ничего не поменяла. Дальше обновление
# всегда осознанный шаг: nix flake update правит flake.lock, и это видно в git.
{
  description = "NixOS + Hyprland — Huawei MateBook";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/2c423e03bbafcff28bfadc6781a4a8257f205cb5";

    home-manager = {
      url = "github:nix-community/home-manager";
      # Home Manager должен собирать пакеты из того же nixpkgs, что и система,
      # иначе в системе окажутся две разные версии одних и тех же библиотек.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        # чтобы модули могли ссылаться на сами inputs (см. nix.registry ниже)
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos/configuration.nix

          # Home Manager подключён как модуль NixOS: одна команда
          # nixos-rebuild switch собирает и систему, и домашний каталог.
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;    # тот же pkgs, что у системы
            home-manager.useUserPackages = true;  # пакеты в /etc/profiles, а не в ~/.nix-profile
            home-manager.backupFileExtension = "hm-bak";
            home-manager.users.roman = import ./home/roman.nix;
          }
        ];
      };
    };
}
