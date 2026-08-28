{ inputs, ... }:

{
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
}