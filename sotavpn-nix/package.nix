{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, wrapGAppsHook3
, makeWrapper
, zstd
  # GUI (Flutter/GTK) runtime libs
, glib
, gtk3
, atk
, pango
, cairo
, gdk-pixbuf
, harfbuzz
, libepoxy
, fontconfig
, zlib
, curl
, libglvnd
  # tray icon
, libayatana-appindicator
, libayatana-indicator
, ayatana-ido
, libdbusmenu
  # the daemon shells out to `ip`
, iproute2
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sotavpn";
  version = "1.8.0+1160-1";

  # Upstream only publishes a "latest" artifact — there is no versioned URL.
  # When Sota ships an update this hash stops matching and the build fails
  # loudly; run ./update.sh to re-pin it (and bump `version` from .PKGINFO).
  src = fetchurl {
    url = "https://storage.sota.ac/api/v1/public/storage/sotavpn-latest-x64.pkg.tar.zst";
    hash = "sha256-riy17Nn+jKi7KlXBrSaITqDgVjGqSHAeyJT6CTc6BsI=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
    makeWrapper
    zstd
  ];

  buildInputs = [
    glib
    gtk3
    atk
    pango
    cairo
    gdk-pixbuf
    harfbuzz
    libepoxy
    fontconfig
    zlib
    curl
    libayatana-appindicator
    libayatana-indicator
    ayatana-ido
    libdbusmenu
    stdenv.cc.cc.lib # libstdc++ / libgcc_s
  ];

  # lib/libdartjni.so wants libjvm.so, which is absent on the vendor's own
  # Debian/Arch packages too — the plugin is never loaded on Linux.
  autoPatchelfIgnoreMissingDeps = [ "libjvm.so" ];

  # An Arch package, not a normal tarball.
  unpackPhase = ''
    runHook preUnpack
    mkdir -p source
    tar --zstd -xf $src -C source
    runHook postUnpack
  '';

  sourceRoot = "source";

  # The GUI is wrapped by hand in postFixup; the daemon must stay unwrapped.
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/libexec $out/share/applications

    # Flutter bundle: the executable finds data/ and lib/ next to itself
    # (via /proc/self/exe), so the whole directory has to move as one unit.
    cp -r usr/lib/sota-connect $out/lib/
    cp -r usr/libexec/sota-daemon $out/libexec/
    cp -r usr/share/icons $out/share/

    substitute usr/share/applications/org.interhive.sota.connect.desktop \
      $out/share/applications/org.interhive.sota.connect.desktop \
      --replace-fail "/usr/bin/sotavpn" "$out/bin/sotavpn"

    runHook postInstall
  '';

  postFixup = ''
    mkdir -p $out/bin

    # GUI: needs the GTK/GSettings environment plus a libGL that libepoxy
    # can dlopen. /run/opengl-driver/lib comes from hardware.graphics.
    makeWrapper $out/lib/sota-connect/sotavpn $out/bin/sotavpn \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libglvnd ]}"

    # Daemon: resolves `sing-box` relative to itself, so it only needs `ip`
    # on PATH. Keep it a wrapper, not a symlink, for people who run it by hand.
    makeWrapper $out/libexec/sota-daemon/sotad $out/bin/sotad \
      --prefix PATH : "${lib.makeBinPath [ iproute2 ]}"
  '';

  meta = {
    description = "Sota Connect — VPN client (proprietary, repackaged from the vendor's Arch build)";
    homepage = "https://sotavpn.com/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "sotavpn";
  };
})
