{pkgs, ...}:

{
  #############################################################
  ## Японский ввод: fcitx5 + mozc
  #############################################################
  # en/ru по-прежнему переключает сам Hyprland (Alt+Shift) — это не тронуто.
  # Японский устроен иначе: иероглифы не лежат на клавишах, их набирают
  # латиницей, а движок mozc превращает ромадзи в кану и предлагает кандзи.
  # Поэтому отдельная xkb-раскладка "jp" не нужна — она описывает физическую
  # японскую клавиатуру, а не сам ввод. Ctrl+Space включает и выключает mozc.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;                  # ввод через родной wayland-протокол
      addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
      settings = {
        # Это только стартовый набор: при первом же изменении fcitx5 заведёт
        # свои файлы в ~/.config/fcitx5 и дальше читает уже их, а не эти.
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0" = { Name = "keyboard-us"; Layout = ""; };
          "Groups/0/Items/1" = { Name = "mozc";        Layout = ""; };
          GroupOrder = { "0" = "Default"; };
        };
        globalOptions = {
          Hotkey = { EnumerateWithTriggerKeys = "True"; };
          "Hotkey/TriggerKeys" = { "0" = "Control+space"; };
          "Hotkey/EnumerateForwardKeys" = { "0" = "Control+space"; };
          Behavior = { ActiveByDefault = "False"; };
        };
      };
    };
  };
}