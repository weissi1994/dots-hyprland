{
  rev,
  lib,
  stdenv,
  makeWrapper,
  makeFontsConf,
  python311,
  python311Packages,
  nodejs,
  nodePackages,
  jq,
  curl,
  grim,
  swappy,
  wl-clipboard,
  libqalculate,
  inotify-tools,
  bluez,
  bash,
  hyprland,
  coreutils,
  findutils,
  file,
  networkmanager,
  brightnessctl,
  ddcutil,
  lm_sensors,
  translate-shell,
  fuzzel,
  hyprpicker,
  hypridle,
  hyprlock,
  wlogout,
  cliphist,
  material-symbols,
  nerd-fonts,
  quickshell,
  hyprsunset ? null,
  easyeffects ? null,
  nm-connection-editor ? null,
}:
let
  # Core runtime dependencies from illogical-impulse PKGBUILDs
  runtimeDeps = [
    # Basic utilities
    bash
    coreutils
    findutils
    file
    jq
    curl
    inotify-tools

    # Wayland/Hyprland tools
    hyprland
    hyprpicker
    hypridle
    hyprlock
    grim
    swappy
    wl-clipboard
    cliphist

    # System control
    brightnessctl
    ddcutil
    lm_sensors
    bluez
    networkmanager

    # UI tools
    fuzzel
    wlogout
    translate-shell
    libqalculate

    # Optional dependencies
  ]
  ++ lib.optionals (hyprsunset != null) [ hyprsunset ]
  ++ lib.optionals (easyeffects != null) [ easyeffects ]
  ++ lib.optionals (nm-connection-editor != null) [ nm-connection-editor ];

  # Python environment for scripts
  pythonEnv = python311.withPackages (
    ps: with ps; [
      pillow
      material-color-utilities
      requests
      pygobject3
    ]
  );

  # Font configuration
  fontconfig = makeFontsConf {
    fontDirectories = [
      material-symbols
      nerd-fonts.jetbrains-mono
    ];
  };
in
stdenv.mkDerivation {
  pname = "illogical-impulse";
  version = "${rev}";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    quickshell
    pythonEnv
    nodejs
  ];
  propagatedBuildInputs = runtimeDeps;

  buildPhase = ''
    # Create Python virtual environment directory structure
    mkdir -p share/quickshell/.venv/lib/python3.11/site-packages

    # Install Python dependencies to virtual env
    export PYTHONPATH=$PYTHONPATH:${pythonEnv}/${python311.sitePackages}
  '';

  installPhase = ''
    # Create output directories
    mkdir -p $out/share/illogical-impulse
    mkdir -p $out/bin

    # Copy quickshell configuration
    cp -r .config/* $out/share/illogical-impulse/

    # Fix Python scripts with problematic shebangs
    find $out/share/illogical-impulse -name "*.py" -type f -exec sed -i '1s|^#!/usr/bin/env -S.*|#!/usr/bin/env python3|' {} \;

    # Set up virtual environment location
    mkdir -p $out/share/illogical-impulse/.venv
    ln -s ${pythonEnv}/lib/python*/site-packages $out/share/illogical-impulse/.venv/lib

    # Create wrapper script
    makeWrapper ${quickshell}/bin/qs $out/bin/illogical-impulse \
      --prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set ILLOGICAL_IMPULSE_VIRTUAL_ENV "$out/share/illogical-impulse/.venv" \
      --set PYTHONPATH "${pythonEnv}/${python311.sitePackages}" \
      --add-flags "-p $out/share/illogical-impulse/quickshell/ii"
      
  '';

  meta = with lib; {
    description = "illogical-impulse: A Material Design quickshell configuration for Hyprland";
    homepage = "https://github.com/end-4/dots-hyprland";
    license = licenses.gpl3Plus;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "illogical-impulse";
  };
}
