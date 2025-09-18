{
  config,
  lib,
  pkgs,
  illogical-impulse,
  ...
}:

let
  cfg = config.programs.illogical-impulse;

  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    ;
  inherit (cfg)
    policies
    ai
    appearance
    audio
    apps
    background
    bar
    battery
    dock
    interactions
    language
    light
    media
    networking
    osd
    osk
    overview
    resources
    search
    sidebar
    time
    windows
    hacks
    grafana
    screenshotTool
    ;

  # Helper function to convert Nix config to JSON format expected by the QML config
  configToJson =
    cfg:
    builtins.toJSON {
      inherit
        policies
        ai
        apps
        media
        networking
        ;

      appearance = {
        inherit (appearance) extraBackgroundTint fakeScreenRounding transparency;
        wallpaperTheming = {
          inherit (appearance.wallpaperTheming) enableAppsAndShell enableQtApps enableTerminal;
        };
        palette = {
          inherit (appearance.palette) type;
        };
      };

      audio = {
        protection = {
          inherit (audio.protection) enable maxAllowedIncrease maxAllowed;
        };
      };

      background = {
        inherit (background)
          fixedClockPosition
          clockX
          clockY
          wallpaperPath
          thumbnailPath
          ;
        parallax = {
          inherit (background.parallax) enableWorkspace workspaceZoom enableSidebar;
        };
      };

      bar = {
        inherit (bar)
          bottom
          cornerStyle
          borderless
          topLeftIcon
          showBackground
          verbose
          screenList
          ;
        autoHide = {
          inherit (bar.autoHide) enable pushWindows;
          showWhenPressingSuper = {
            inherit (bar.autoHide.showWhenPressingSuper) enable delay;
          };
        };
        resources = {
          inherit (bar.resources) alwaysShowSwap alwaysShowCpu;
        };
        utilButtons = {
          inherit (bar.utilButtons)
            showScreenSnip
            showColorPicker
            showMicToggle
            showKeyboardToggle
            showDarkModeToggle
            showPerformanceProfileToggle
            ;
        };
        tray = {
          inherit (bar.tray) monochromeIcons;
        };
        workspaces = {
          inherit (bar.workspaces)
            monochromeIcons
            shown
            showAppIcons
            alwaysShowNumbers
            showNumberDelay
            ;
        };
        weather = {
          inherit (bar.weather)
            enable
            enableGPS
            city
            useUSCS
            fetchInterval
            ;
        };
      };

      battery = {
        inherit (battery)
          low
          critical
          automaticSuspend
          suspend
          ;
      };

      dock = {
        inherit (dock)
          enable
          monochromeIcons
          height
          hoverRegionHeight
          pinnedOnStartup
          hoverToReveal
          pinnedApps
          ignoredAppRegexes
          ;
      };

      interactions = {
        scrolling = {
          inherit (interactions.scrolling)
            fasterTouchpadScroll
            mouseScrollDeltaThreshold
            mouseScrollFactor
            touchpadScrollFactor
            ;
        };
      };

      language = {
        translator = {
          inherit (language.translator) engine targetLanguage sourceLanguage;
        };
      };

      light = {
        night = {
          inherit (light.night)
            automatic
            from
            to
            colorTemperature
            ;
        };
      };

      osd = {
        inherit (osd) timeout;
      };

      osk = {
        inherit (osk) layout pinnedOnStartup;
      };

      overview = {
        inherit (overview)
          enable
          scale
          rows
          columns
          ;
      };

      resources = {
        inherit (resources) updateInterval;
      };

      search = {
        inherit (search)
          nonAppResultDelay
          engineBaseUrl
          excludedSites
          sloppy
          ;
        prefix = {
          inherit (search.prefix) action clipboard emojis;
        };
      };

      sidebar = {
        inherit (sidebar) keepRightSidebarLoaded;
        translator = {
          inherit (sidebar.translator) delay;
        };
      };

      time = {
        inherit (time) format dateFormat;
        pomodoro = {
          inherit (time.pomodoro)
            alertSound
            breakTime
            cyclesBeforeLongBreak
            focus
            longBreak
            ;
        };
      };

      windows = {
        inherit (windows) showTitlebar centerTitle;
      };

      hacks = {
        inherit (hacks) arbitraryRaceConditionDelay;
      };

      grafana = {
        inherit (grafana)
          enable
          url
          apiToken
          refreshInterval
          notifications
          instances
          ;
        filters = {
          inherit (grafana.filters)
            alertName
            folder
            excludeAlertName
            excludeFolder
            ;
        };
      };

      screenshotTool = {
        inherit (screenshotTool) showContentRegions;
      };
    };

in
{
  options.programs.illogical-impulse = {
    enable = mkEnableOption "illogical-impulse configuration";
    package = mkOption {
      type = types.package;
      default = illogical-impulse;
      description = "The illogical-impulse package to use";
    };

    policies = {
      ai = mkOption {
        type = types.int;
        default = 1;
        description = "AI policy: 0 = No, 1 = Yes, 2 = Local";
      };
      weeb = mkOption {
        type = types.int;
        default = 1;
        description = "Weeb policy: 0 = No, 1 = Open, 2 = Closet";
      };
    };

    ai = {
      systemPrompt = mkOption {
        type = types.str;
        default = "## Style\n- Use casual tone, don't be formal! Make sure you answer precisely without hallucination and prefer bullet points over walls of text. You can have a friendly greeting at the beginning of the conversation, but don't repeat the user's question\n\n## Context (ignore when irrelevant)\n- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system\n- Desktop environment: {DE}\n- Current date & time: {DATETIME}\n- Focused app: {WINDOWCLASS}\n\n## Presentation\n- Use Markdown features in your response: \n  - **Bold** text to **highlight keywords** in your response\n  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.\n- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!\n- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).\n";
        description = "System prompt for AI assistant";
      };
      tool = mkOption {
        type = types.enum [
          "search"
          "functions"
          "none"
        ];
        default = "functions";
        description = "AI tool mode";
      };
      extraModels = mkOption {
        type = types.listOf types.attrs;
        default = [
          {
            api_format = "openai";
            description = "This is a custom model. Edit the config to add more! | Anyway, this is DeepSeek R1 Distill LLaMA 70B";
            endpoint = "https://openrouter.ai/api/v1/chat/completions";
            homepage = "https://openrouter.ai/deepseek/deepseek-r1-distill-llama-70b:free";
            icon = "spark-symbolic";
            key_get_link = "https://openrouter.ai/settings/keys";
            key_id = "openrouter";
            model = "deepseek/deepseek-r1-distill-llama-70b:free";
            name = "Custom: DS R1 Dstl. LLaMA 70B";
            requires_key = true;
          }
        ];
        description = "Extra AI models configuration";
      };
    };

    appearance = {
      extraBackgroundTint = mkOption {
        type = types.bool;
        default = true;
        description = "Enable extra background tint";
      };
      fakeScreenRounding = mkOption {
        type = types.int;
        default = 2;
        description = "Fake screen rounding: 0 = None, 1 = Always, 2 = When not fullscreen";
      };
      transparency = mkOption {
        type = types.bool;
        default = false;
        description = "Enable transparency";
      };
      wallpaperTheming = {
        enableAppsAndShell = mkOption {
          type = types.bool;
          default = true;
          description = "Enable wallpaper theming for apps and shell";
        };
        enableQtApps = mkOption {
          type = types.bool;
          default = true;
          description = "Enable wallpaper theming for Qt apps";
        };
        enableTerminal = mkOption {
          type = types.bool;
          default = true;
          description = "Enable wallpaper theming for terminal";
        };
      };
      palette = {
        type = mkOption {
          type = types.enum [
            "auto"
            "scheme-content"
            "scheme-expressive"
            "scheme-fidelity"
            "scheme-fruit-salad"
            "scheme-monochrome"
            "scheme-neutral"
            "scheme-rainbow"
            "scheme-tonal-spot"
          ];
          default = "auto";
          description = "Color palette type";
        };
      };
    };

    audio = {
      protection = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable audio protection to prevent sudden bangs";
        };
        maxAllowedIncrease = mkOption {
          type = types.float;
          default = 10.0;
          description = "Maximum allowed volume increase (%)";
        };
        maxAllowed = mkOption {
          type = types.float;
          default = 90.0;
          description = "Maximum allowed volume (%)";
        };
      };
    };

    apps = {
      bluetooth = mkOption {
        type = types.str;
        default = "kcmshell6 kcm_bluetooth";
        description = "Bluetooth settings command";
      };
      network = mkOption {
        type = types.str;
        default = "plasmawindowed org.kde.plasma.networkmanagement";
        description = "Network settings command";
      };
      networkEthernet = mkOption {
        type = types.str;
        default = "kcmshell6 kcm_networkmanagement";
        description = "Ethernet network settings command";
      };
      taskManager = mkOption {
        type = types.str;
        default = "plasma-systemmonitor --page-name Processes";
        description = "Task manager command";
      };
      terminal = mkOption {
        type = types.str;
        default = "kitty -1";
        description = "Terminal command for shell actions";
      };
    };

    background = {
      fixedClockPosition = mkOption {
        type = types.bool;
        default = true;
        description = "Use fixed clock position";
      };
      clockX = mkOption {
        type = types.float;
        default = 9999.0;
        description = "Clock X position";
      };
      clockY = mkOption {
        type = types.float;
        default = 9999.0;
        description = "Clock Y position";
      };
      wallpaperPath = mkOption {
        type = types.str;
        default = "files/assets/images/default_wallpaper.png";
        description = "Wallpaper file path";
      };
      thumbnailPath = mkOption {
        type = types.str;
        default = "files/assets/images/default_wallpaper.png";
        description = "Wallpaper thumbnail path";
      };
      parallax = {
        enableWorkspace = mkOption {
          type = types.bool;
          default = true;
          description = "Enable workspace parallax";
        };
        workspaceZoom = mkOption {
          type = types.float;
          default = 1.07;
          description = "Workspace zoom level (relative to screen size)";
        };
        enableSidebar = mkOption {
          type = types.bool;
          default = true;
          description = "Enable sidebar parallax";
        };
      };
    };

    bar = {
      autoHide = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable auto-hide bar";
        };
        pushWindows = mkOption {
          type = types.bool;
          default = false;
          description = "Push windows when bar is shown";
        };
        showWhenPressingSuper = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Show bar when pressing Super key";
          };
          delay = mkOption {
            type = types.int;
            default = 140;
            description = "Delay before showing bar (ms)";
          };
        };
      };
      bottom = mkOption {
        type = types.bool;
        default = false;
        description = "Position bar at bottom instead of top";
      };
      cornerStyle = mkOption {
        type = types.int;
        default = 0;
        description = "Bar corner style: 0 = Hug, 1 = Float, 2 = Plain rectangle";
      };
      borderless = mkOption {
        type = types.bool;
        default = false;
        description = "Remove grouping of items";
      };
      topLeftIcon = mkOption {
        type = types.enum [
          "distro"
          "spark"
        ];
        default = "spark";
        description = "Top left icon type";
      };
      showBackground = mkOption {
        type = types.bool;
        default = true;
        description = "Show bar background";
      };
      verbose = mkOption {
        type = types.bool;
        default = true;
        description = "Enable verbose output";
      };
      resources = {
        alwaysShowSwap = mkOption {
          type = types.bool;
          default = true;
          description = "Always show swap usage";
        };
        alwaysShowCpu = mkOption {
          type = types.bool;
          default = false;
          description = "Always show CPU usage";
        };
      };
      screenList = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of screen names (e.g., 'eDP-1')";
      };
      utilButtons = {
        showScreenSnip = mkOption {
          type = types.bool;
          default = true;
          description = "Show screen snip button";
        };
        showColorPicker = mkOption {
          type = types.bool;
          default = false;
          description = "Show color picker button";
        };
        showMicToggle = mkOption {
          type = types.bool;
          default = false;
          description = "Show microphone toggle button";
        };
        showKeyboardToggle = mkOption {
          type = types.bool;
          default = true;
          description = "Show keyboard toggle button";
        };
        showDarkModeToggle = mkOption {
          type = types.bool;
          default = true;
          description = "Show dark mode toggle button";
        };
        showPerformanceProfileToggle = mkOption {
          type = types.bool;
          default = false;
          description = "Show performance profile toggle button";
        };
      };
      tray = {
        monochromeIcons = mkOption {
          type = types.bool;
          default = true;
          description = "Use monochrome tray icons";
        };
      };
      workspaces = {
        monochromeIcons = mkOption {
          type = types.bool;
          default = true;
          description = "Use monochrome workspace icons";
        };
        shown = mkOption {
          type = types.int;
          default = 10;
          description = "Number of workspaces shown";
        };
        showAppIcons = mkOption {
          type = types.bool;
          default = true;
          description = "Show app icons in workspaces";
        };
        alwaysShowNumbers = mkOption {
          type = types.bool;
          default = false;
          description = "Always show workspace numbers";
        };
        showNumberDelay = mkOption {
          type = types.int;
          default = 300;
          description = "Delay before showing workspace numbers (ms)";
        };
      };
      weather = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable weather widget";
        };
        enableGPS = mkOption {
          type = types.bool;
          default = true;
          description = "Use GPS-based location";
        };
        city = mkOption {
          type = types.str;
          default = "";
          description = "City name when GPS is disabled";
        };
        useUSCS = mkOption {
          type = types.bool;
          default = false;
          description = "Use US Customary System instead of metric units";
        };
        fetchInterval = mkOption {
          type = types.int;
          default = 10;
          description = "Weather fetch interval (minutes)";
        };
      };
    };

    battery = {
      low = mkOption {
        type = types.int;
        default = 20;
        description = "Low battery threshold (%)";
      };
      critical = mkOption {
        type = types.int;
        default = 5;
        description = "Critical battery threshold (%)";
      };
      automaticSuspend = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic suspend on low battery";
      };
      suspend = mkOption {
        type = types.int;
        default = 3;
        description = "Battery level to suspend at (%)";
      };
    };

    dock = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable dock";
      };
      monochromeIcons = mkOption {
        type = types.bool;
        default = true;
        description = "Use monochrome dock icons";
      };
      height = mkOption {
        type = types.float;
        default = 60.0;
        description = "Dock height";
      };
      hoverRegionHeight = mkOption {
        type = types.float;
        default = 2.0;
        description = "Hover region height";
      };
      pinnedOnStartup = mkOption {
        type = types.bool;
        default = false;
        description = "Pin dock on startup";
      };
      hoverToReveal = mkOption {
        type = types.bool;
        default = true;
        description = "Reveal dock on hover (when false, only reveals on empty workspace)";
      };
      pinnedApps = mkOption {
        type = types.listOf types.str;
        default = [
          "org.kde.dolphin"
          "kitty"
        ];
        description = "List of pinned app IDs";
      };
      ignoredAppRegexes = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of app regex patterns to ignore";
      };
    };

    interactions = {
      scrolling = {
        fasterTouchpadScroll = mkOption {
          type = types.bool;
          default = true;
          description = "Enable faster scrolling with touchpad";
        };
        mouseScrollDeltaThreshold = mkOption {
          type = types.int;
          default = 120;
          description = "Delta threshold to detect mouse scroll vs touchpad";
        };
        mouseScrollFactor = mkOption {
          type = types.int;
          default = 120;
          description = "Mouse scroll factor";
        };
        touchpadScrollFactor = mkOption {
          type = types.int;
          default = 450;
          description = "Touchpad scroll factor";
        };
      };
    };

    language = {
      translator = {
        engine = mkOption {
          type = types.str;
          default = "auto";
          description = "Translation engine (run 'trans -list-engines' for available)";
        };
        targetLanguage = mkOption {
          type = types.str;
          default = "auto";
          description = "Target language (run 'trans -list-all' for available)";
        };
        sourceLanguage = mkOption {
          type = types.str;
          default = "auto";
          description = "Source language (run 'trans -list-all' for available)";
        };
      };
    };

    light = {
      night = {
        automatic = mkOption {
          type = types.bool;
          default = true;
          description = "Enable automatic night mode";
        };
        from = mkOption {
          type = types.str;
          default = "19:00";
          description = "Night mode start time (HH:mm format)";
        };
        to = mkOption {
          type = types.str;
          default = "06:30";
          description = "Night mode end time (HH:mm format)";
        };
        colorTemperature = mkOption {
          type = types.int;
          default = 5000;
          description = "Night mode color temperature";
        };
      };
    };

    media = {
      filterDuplicatePlayers = mkOption {
        type = types.bool;
        default = true;
        description = "Filter duplicate media players";
      };
    };

    networking = {
      userAgent = mkOption {
        type = types.str;
        default = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36";
        description = "User agent string for network requests";
      };
    };

    osd = {
      timeout = mkOption {
        type = types.int;
        default = 1000;
        description = "OSD timeout (ms)";
      };
    };

    osk = {
      layout = mkOption {
        type = types.str;
        default = "qwerty_full";
        description = "On-screen keyboard layout";
      };
      pinnedOnStartup = mkOption {
        type = types.bool;
        default = false;
        description = "Pin OSK on startup";
      };
    };

    overview = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable overview";
      };
      scale = mkOption {
        type = types.float;
        default = 0.18;
        description = "Overview scale (relative to screen size)";
      };
      rows = mkOption {
        type = types.float;
        default = 2.0;
        description = "Overview rows";
      };
      columns = mkOption {
        type = types.float;
        default = 5.0;
        description = "Overview columns";
      };
    };

    resources = {
      updateInterval = mkOption {
        type = types.int;
        default = 3000;
        description = "Resource monitoring update interval (ms)";
      };
    };

    search = {
      nonAppResultDelay = mkOption {
        type = types.int;
        default = 30;
        description = "Delay for non-app search results to prevent lag";
      };
      engineBaseUrl = mkOption {
        type = types.str;
        default = "https://www.google.com/search?q=";
        description = "Search engine base URL";
      };
      excludedSites = mkOption {
        type = types.listOf types.str;
        default = [ "quora.com" ];
        description = "List of sites to exclude from search";
      };
      sloppy = mkOption {
        type = types.bool;
        default = false;
        description = "Use levenshtein distance based scoring instead of fuzzy sort";
      };
      prefix = {
        action = mkOption {
          type = types.str;
          default = "/";
          description = "Action search prefix";
        };
        clipboard = mkOption {
          type = types.str;
          default = ";";
          description = "Clipboard search prefix";
        };
        emojis = mkOption {
          type = types.str;
          default = ":";
          description = "Emoji search prefix";
        };
      };
    };

    sidebar = {
      keepRightSidebarLoaded = mkOption {
        type = types.bool;
        default = true;
        description = "Keep right sidebar loaded";
      };
      translator = {
        delay = mkOption {
          type = types.int;
          default = 300;
          description = "Translator request delay to reduce rate limits (ms)";
        };
      };
    };

    time = {
      format = mkOption {
        type = types.str;
        default = "hh:mm";
        description = "Time format (Qt format string)";
      };
      dateFormat = mkOption {
        type = types.str;
        default = "ddd, dd/MM";
        description = "Date format (Qt format string)";
      };
      pomodoro = {
        alertSound = mkOption {
          type = types.str;
          default = "";
          description = "Pomodoro alert sound file path";
        };
        breakTime = mkOption {
          type = types.int;
          default = 300;
          description = "Pomodoro break time (seconds)";
        };
        cyclesBeforeLongBreak = mkOption {
          type = types.int;
          default = 4;
          description = "Cycles before long break";
        };
        focus = mkOption {
          type = types.int;
          default = 1500;
          description = "Pomodoro focus time (seconds)";
        };
        longBreak = mkOption {
          type = types.int;
          default = 900;
          description = "Pomodoro long break time (seconds)";
        };
      };
    };

    windows = {
      showTitlebar = mkOption {
        type = types.bool;
        default = true;
        description = "Show titlebar for shell apps (client-side decoration)";
      };
      centerTitle = mkOption {
        type = types.bool;
        default = true;
        description = "Center window titles";
      };
    };

    hacks = {
      arbitraryRaceConditionDelay = mkOption {
        type = types.int;
        default = 20;
        description = "Arbitrary race condition delay (ms)";
      };
    };

    screenshotTool = {
      showContentRegions = mkOption {
        type = types.bool;
        default = true;
        description = "Show content regions in screenshot tool";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.qickshell = {
      Unit = {
        Description = "illogical-impulse quickshell";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/illogical-impulse";
        Restart = "always";
        RestartSec = 3;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    home.file.".config/illogical-impulse/config.json" = {
      text = configToJson cfg;
      onChange = ''
        # Reload quickshell if it's running
        systemctl --user reload-or-restart qickshell.service
      '';
    };
    home.packages = [
      cfg.package
      pkgs.grimblast
      pkgs.wl-clipboard
      pkgs.swww
      pkgs.cliphist
      pkgs.libnotify
      pkgs.inotify-tools
      pkgs.libsecret
      pkgs.socat
      pkgs.brightnessctl
      pkgs.hyprshade
      pkgs.desktop-file-utils
    ];
  };
}
