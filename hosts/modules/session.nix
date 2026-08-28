{ pkgs, ... }:

{
  #############################################################
  ## Hyprland / графическая сессия
  #############################################################
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";                       # Chrome/Electron нативно в Wayland
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Ice";
    HYPRCURSOR_SIZE = "24";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  security.polkit.enable = true;
  systemd.packages = [ pkgs.hyprpolkitagent ];  # user-юнит агента запроса прав
  security.pam.services.hyprlock = {};           # разблокировка экрана
  services.gnome.gnome-keyring.enable = true;    # хранилище паролей (нужно Chrome)
  programs.dconf.enable = true;

  # Экран входа
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --sessions /run/current-system/sw/share/wayland-sessions";
      user = "greeter";
    };
  };

  # Тема Qt-приложений в тон GTK
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;             # 32-битные игры в Steam
  };
}