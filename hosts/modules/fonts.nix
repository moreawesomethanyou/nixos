{ pkgs, ... }:

{
  #############################################################
  ## Шрифты
  #############################################################
  fonts = {
    packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      nerd-fonts.jetbrains-mono
    ];
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Inter" "Noto Sans" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}