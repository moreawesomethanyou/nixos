# Общая часть системы: всё, что одинаково на ноутбуке и на стационарном
# компьютере. Железозависимое лежит рядом, в hosts/<хост>/configuration.nix:
# Все общие модули - в hosts/modules
#   hosts/nixos/    — Huawei MateBook (Intel Alder Lake + встроенная графика)
#   hosts/desktop/  — стационарный (AMD + видеокарта AMD)
#
# Правь модули в hosts/modules, если изменение должно появиться на обеих машинах.
# Применить: rebuild (= sudo nixos-rebuild switch --flake ~/nixos-config)

{ ... }:

{
  imports = [ ./modules ];
  system.stateVersion = "26.05"; # НЕ МЕНЯТЬ
}
