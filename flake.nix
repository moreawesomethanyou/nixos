# Флейк всей системы: NixOS + Home Manager для Huawei MateBook.
#
#   Пересобрать систему:   sudo nixos-rebuild switch --flake ~/nixos-config#nixos
#   Обновить пакеты:       nix flake update --flake ~/nixos-config   (потом switch)
#   Откатиться:            sudo nixos-rebuild switch --rollback
#
# nixpkgs специально запинен на коммит, из которого собрана система на момент
# перехода на флейки, — чтобы первая сборка ничего не меняла. Обновление
# теперь всегда осознанный шаг: nix flake update правит flake.lock, и его
# видно в git diff.
{
  description = "NixOS + Hyprland — Huawei MateBook";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/2c423e03bbafcff28bfadc6781a4a8257f205cb5";
  };

  outputs = { self, nixpkgs, ... }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/configuration.nix
        ];
      };
    };
}
