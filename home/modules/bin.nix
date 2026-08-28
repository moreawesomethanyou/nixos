{ lib, ... }:

{
  #############################################################
  ## Скрипты в ~/.local/bin
  #############################################################
  # На них ссылаются биндинги Hyprland, hypridle и модули waybar —
  # именно по пути ~/.local/bin, поэтому кладём их туда же.
  home.file = lib.genAttrs
    (map (n: ".local/bin/${n}")
      [ "hypr-display" "hypr-dpms" "hypr-lid" "lang-indicator" "lang-poke" "power-mode" ])
    (name: {
      source = ../bin + "/${baseNameOf name}";
      executable = true;
    });
}
