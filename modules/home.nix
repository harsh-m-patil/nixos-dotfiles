{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles;
  jsonType = (pkgs.formats.json { }).type;
  str =
    default: description:
    lib.mkOption {
      type = lib.types.str;
      inherit default description;
    };
  widgetList =
    default:
    lib.mkOption {
      type = lib.types.listOf (lib.types.enum widgets);
      inherit default;
    };
  widgets = [
    "workspaces"
    "windowTitle"
    "media"
    "clock"
    "f1"
    "agentUsage"
    "tray"
    "status"
  ];
  home = config.home.homeDirectory;
  sessionVariables = {
    DOTFILES = cfg.path;
  };
in
{
  options.dotfiles = {
    enable = lib.mkEnableOption "the Hyprland + Quickshell desktop config" // {
      default = true;
    };

    path = lib.mkOption {
      type = lib.types.str;
      default = "${home}/nixos-dotfiles";
      description = "Where this repo is cloned. Desktop configs are stowed from here so they stay editable.";
    };

    quickshellPackage = lib.mkOption {
      type = lib.types.package;
      description = "Quickshell build used for the bar.";
    };

    settings = lib.mkOption {
      description = ''
        User settings, written to ~/.config/dotfiles/settings.{json,lua} and read by Hyprland and the bar.
        Unknown keys are allowed and passed through for your own modules.
      '';
      default = { };
      type = lib.types.submodule {
        freeformType = jsonType;
        options = {
          apps = {
            terminal = str "ghostty" "Super+Return";
            browser = str "firefox" "Super+B";
            fileManager = str "nautilus" "Super+E";
            launcher = str "vicinae open" "Super+R";
          };
          input = {
            kbLayout = str "us" "XKB layout, e.g. \"us,de\".";
            kbVariant = str "" "XKB variant.";
            kbOptions = str "" "XKB options, e.g. \"caps:escape\".";
            naturalScroll = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            sensitivity = lib.mkOption {
              type = lib.types.number;
              default = 0;
              description = "-1.0 to 1.0.";
            };
          };
          monitor.scale = lib.mkOption {
            type = lib.types.number;
            default = 1;
            description = "Default scale for every display; per-output rules go in config/hypr/local.lua.";
          };
          theme = {
            default = str "rose-pine" "Theme applied on first switch (later changes are kept in state).";
            packs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "core" ];
              description = "Theme packs from themes/<pack>/ to include, e.g. [ \"core\" \"f1\" ].";
            };
          };
          wallpapers.dir = str "${home}/Walls" "Wallpaper root; theme pools live in <dir>/f1/<pool>/.";
          bar = {
            left = widgetList [
              "workspaces"
              "windowTitle"
            ];
            center = widgetList [
              "media"
              "clock"
            ];
            right = widgetList [
              "tray"
              "status"
            ];
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."dotfiles/settings.json".text = builtins.toJSON cfg.settings;
    xdg.configFile."dotfiles/settings.lua".text =
      "return " + lib.generators.toLua { } cfg.settings + "\n";

    home.packages = [
      cfg.quickshellPackage
      (pkgs.writeShellScriptBin "dotfiles" ''
        export DOTFILES="''${DOTFILES:-${cfg.path}}"
        exec ${pkgs.bash}/bin/bash "$DOTFILES/scripts/dotfiles" "$@"
      '')
    ];

    programs.vicinae = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.vicinae;
    };

    # GTK / libadwaita / Qt apps follow the dark desktop.
    dconf.enable = true;
    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
    gtk = {
      enable = true;
      colorScheme = "dark";
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      gtk4 = {
        theme = config.gtk.theme;
        extraConfig.gtk-application-prefer-dark-theme = true;
      };
    };
    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt6;
      };
    };
    home.sessionVariables = sessionVariables;
    systemd.user.sessionVariables = sessionVariables;

    # Never use `exit` in activation snippets: it aborts the rest of home-manager activation.

    # Migrations, then stow stow/home → ~/.config/{hypr,quickshell,...} as links into the repo.
    home.activation.stowConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export DOTFILES="${cfg.path}"
      if [ ! -d "$DOTFILES/stow/home/.config/hypr" ]; then
        echo "dotfiles: $DOTFILES is missing; clone the repo there or set dotfiles.path"
      else
        ${pkgs.bash}/bin/bash "$DOTFILES/scripts/migrate.sh" \
          || echo "dotfiles: a migration failed; continuing activation"
        ${pkgs.stow}/bin/stow -R --target="${home}" --dir="$DOTFILES/stow" home \
          || echo "dotfiles: stow failed (conflicts are ok); continuing activation"
      fi
    '';

    # Ghostty and Starship read merged configs; theme fragments live in writable state (see apply-theme.sh).
    home.activation.assembleThemedConfigs =
      lib.hm.dag.entryAfter [ "writeBoundary" "stowConfig" "linkGeneration" ]
        ''
          export PATH="${
            lib.makeBinPath (
              with pkgs;
              [
                jq
                coreutils
                gnused
                gnugrep
                findutils
                python3
              ]
            )
          }:$PATH"
          export DOTFILES="${cfg.path}"
          export WALLS_DIR="${cfg.settings.wallpapers.dir}"
          STATE="${home}/.local/state/quickshell"
          mkdir -p "$STATE"

          ${pkgs.bash}/bin/bash "$DOTFILES/scripts/build-themes.sh" \
            || echo "dotfiles: theme build failed; keeping the previous themes.json"

          THEME_ID="${cfg.settings.theme.default}"
          if [ -f "$STATE/theme-state.json" ]; then
            THEME_ID="$(jq -r --arg d "$THEME_ID" '.id // $d' "$STATE/theme-state.json" 2>/dev/null || echo "$THEME_ID")"
          fi
          if ! jq -e --arg id "$THEME_ID" '.themes[] | select(.id == $id)' "$DOTFILES/config/quickshell/themes.json" >/dev/null 2>&1; then
            THEME_ID="${cfg.settings.theme.default}"
          fi
          APPLY="${home}/.config/quickshell/apply-theme.sh"
          if [ -x "$APPLY" ]; then
            "$APPLY" "$THEME_ID" --no-wallpaper >/dev/null 2>&1 \
              || echo "dotfiles: applying theme $THEME_ID failed"
          fi
        '';

    home.activation.postSwitchHooks = lib.hm.dag.entryAfter [ "assembleThemedConfigs" ] ''
      DOTFILES="${cfg.path}" ${pkgs.bash}/bin/bash "${cfg.path}/scripts/hook.sh" post-switch \
        || echo "dotfiles: a post-switch hook failed; continuing activation"
    '';
  };
}
