{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  makeWrapper,
  gtk3,
  nss,
  nspr,
  alsa-lib,
  at-spi2-core,
  cups,
  dbus,
  expat,
  libdrm,
  libxkbcommon,
  libGL,
  mesa,
  systemd,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
}:

stdenv.mkDerivation rec {
  pname = "grok-bot";
  version = "0.75.8";

  src = fetchurl {
    url = "https://api2.cursor.sh/updates/download/stable/linux-x64/grok-bot-fb0a830618be0c54";
    hash = "sha256-Q0ZdsVih2dYYqe+caKrqBj3jQjRG+vdiq+fuSP99Jrs=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
    makeWrapper
  ];

  buildInputs = [
    gtk3
    nss
    nspr
    alsa-lib
    at-spi2-core
    cups
    dbus
    expat
    libdrm
    libxkbcommon
    libGL
    mesa
    systemd
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
  ];

  sourceRoot = "source";
  unpackCmd = "dpkg-deb -x $curSrc source";

  installPhase = ''
    runHook preInstall

    app=$out/opt/grok-bot
    mkdir -p $app $out/bin
    cp -ra opt/Grok\ Bot/. $app/

    makeWrapper $app/grok-bot $out/bin/grok-bot \
      --chdir $app \
      --add-flags "--no-sandbox"

    install -Dm644 usr/share/applications/grok-bot.desktop \
      $out/share/applications/grok-bot.desktop
    substituteInPlace $out/share/applications/grok-bot.desktop \
      --replace-fail 'Exec=grok-bot' 'Exec=grok-bot'

    for size in 16x16 24x24 32x32 48x48 64x64 128x128 256x256 512x512; do
      install -Dm644 usr/share/icons/hicolor/$size/apps/grok-bot.png \
        $out/share/icons/hicolor/$size/apps/grok-bot.png
    done

    runHook postInstall
  '';

  meta = {
    description = "Grok Bot desktop agent";
    homepage = "https://cursor.com";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "grok-bot";
  };
}
