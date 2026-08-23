# GUI для linux-wallpaperengine (проект Suhoiyis/gui-for-linux-wallpaperengine).
# В nixpkgs пакета нет, поэтому собираем сами.
#
# pname намеренно БЕЗ префикса "linux-": программа при остановке обоев выполняет
# `pkill -f linux-wallpaperengine`, и если бы путь /nix/store к самой GUI
# содержал эту подстроку, она убивала бы сама себя. По той же причине argv0
# обёртки переопределён на путь к python (иначе в командной строке процесса
# оказался бы $out/bin/linux-wallpaperengine-gui).
{ lib
, stdenv
, fetchFromGitHub
, python3
, makeWrapper
, wrapGAppsHook4
, gobject-introspection
, gtk4
, gtk3
, libadwaita
, libayatana-appindicator
, glib
, gsettings-desktop-schemas
, adwaita-icon-theme
, librsvg
, gdk-pixbuf
, linux-wallpaperengine
, procps
, xvfb-run
, wlr-randr
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    pygobject3
    pycairo
    pillow
    psutil
  ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "wallpaperengine-gui";
  version = "0.11.2";

  src = fetchFromGitHub {
    owner = "Suhoiyis";
    repo = "gui-for-linux-wallpaperengine";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JJIuzYKmLq8Da5Nl/jwNfLjRMeNLkBBrOmyaTTuJTfE=";
  };

  nativeBuildInputs = [ makeWrapper wrapGAppsHook4 gobject-introspection ];

  buildInputs = [
    gtk4
    gtk3                      # трей работает отдельным процессом на GTK3 + AppIndicator
    libadwaita
    libayatana-appindicator
    glib
    gsettings-desktop-schemas
    adwaita-icon-theme
    librsvg
    gdk-pixbuf
  ];

  # Обёртку делаем вручную (см. комментарий про pkill выше).
  dontWrapGApps = true;
  dontBuild = true;

  # Хардкод путей Debian/Arch, которых на NixOS нет.
  postPatch = ''
    substituteInPlace py_GUI/ui/tray.py \
      --replace-fail '"/usr/bin/python3"' 'sys.executable'
    substituteInPlace py_GUI/core/integrations.py \
      --replace-fail '"/usr/bin/gtk-update-icon-cache"' '"gtk-update-icon-cache"'

    # Пункт трея «Show Window» запускает окно командой ["python3", ...].
    # Голого python3 в PATH на NixOS нет, поэтому пункт молча не работал —
    # в tray_crash.log это видно как
    # `Cmd Error: [Errno 2] No such file or directory: 'python3'`.
    # Ставим sys.executable — тот самый интерпретер, которым запущен трей.
    #
    # Патчить нужно ОБА файла: tray.py хранит копию скрипта трея строкой
    # TRAY_PROCESS_PAYLOAD, и в ~/.cache извлекается именно она, а не
    # соседний tray_process.py.
    substituteInPlace py_GUI/ui/tray.py \
      --replace-fail '["python3", self.run_gui_path, arg]' \
                     '[sys.executable, self.run_gui_path, arg]'

    # Список экранов GUI получал через `xrandr --query`. Это инструмент X11:
    # в вейландовской сессии он недоступен, список выходил пустым, eDP-1 в нём
    # не находился — и GUI молча стирал выбор обоев, даже не запуская движок
    # (в config.json это видно как "active_monitors": {}).
    # Подставляем помощника, который выдаёт тот же формат из wlr-randr.
    substituteInPlace py_GUI/core/screen.py \
      --replace-fail "['xrandr', '--query']" "['$out/libexec/wpe-list-screens']"
    substituteInPlace py_GUI/ui/tray_process.py \
      --replace-fail '["python3", self.run_gui_path, arg]' \
                     '[sys.executable, self.run_gui_path, arg]'
  '';

  installPhase = ''
    runHook preInstall

    appdir=$out/share/wpe-gui
    mkdir -p $appdir
    cp -r py_GUI pic run_gui.py CHANGELOG.md $appdir/
    find $appdir -name __pycache__ -type d -prune -exec rm -rf {} +

    install -Dm644 pic/icons/GUI_rounded.png \
      $out/share/icons/hicolor/512x512/apps/com.wallpaperengine.gui.png

    # Помощник для screen.py (см. postPatch): печатает строки вида
    # "<имя-экрана> connected" — ровно тот формат, который GUI разбирает
    # в выводе xrandr, но данные берёт из wlr-randr, работающего в Wayland.
    # Имена здесь совпадают с теми, что ждёт сам движок в --screen-root.
    mkdir -p $out/libexec
    cat > $out/libexec/wpe-list-screens <<'SCRIPT'
    #!/bin/sh
    ${wlr-randr}/bin/wlr-randr | awk '/^[^ \t]/ { print $1, "connected" }'
    SCRIPT
    sed -i 's/^    //' $out/libexec/wpe-list-screens
    chmod +x $out/libexec/wpe-list-screens

    mkdir -p $out/share/applications
    cat > $out/share/applications/com.wallpaperengine.gui.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Wallpaper Engine
    Comment=Живые обои Wallpaper Engine
    Exec=linux-wallpaperengine-gui %U
    Icon=com.wallpaperengine.gui
    Terminal=false
    Categories=Utility;Graphics;
    StartupNotify=true
    StartupWMClass=com.wallpaperengine.gui
    EOF
    sed -i 's/^    //' $out/share/applications/com.wallpaperengine.gui.desktop

    runHook postInstall
  '';

  # Обёртка создаётся в preFixup, а не в installPhase: массив gappsWrapperArgs
  # (GI_TYPELIB_PATH, XDG_DATA_DIRS, GSETTINGS_SCHEMA_DIR) хук wrapGAppsHook4
  # заполняет только к этому моменту.
  preFixup = ''
    makeWrapper ${pythonEnv}/bin/python3 $out/bin/linux-wallpaperengine-gui \
      --argv0 ${pythonEnv}/bin/python3 \
      --add-flags $out/share/wpe-gui/run_gui.py \
      --set PYTHONDONTWRITEBYTECODE 1 \
      --prefix PATH : ${lib.makeBinPath [ linux-wallpaperengine procps xvfb-run gtk3 ]} \
      "''${gappsWrapperArgs[@]}"
  '';

  meta = {
    description = "GTK4-GUI для linux-wallpaperengine";
    homepage = "https://github.com/Suhoiyis/gui-for-linux-wallpaperengine";
    license = lib.licenses.gpl3Plus;
    mainProgram = "linux-wallpaperengine-gui";
    platforms = lib.platforms.linux;
  };
})
