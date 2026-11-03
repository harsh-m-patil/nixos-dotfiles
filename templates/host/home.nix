{ pkgs, ... }:

# Per-user settings. Every option is documented in modules/home.nix (dotfiles.settings).
{
  home.username = "@USER@";
  home.homeDirectory = "/home/@USER@";
  home.stateVersion = "@STATE_VERSION@";

  dotfiles.settings = {
    apps = {
      terminal = "ghostty";
      browser = "firefox";
      fileManager = "nautilus";
      launcher = "vicinae open";
    };
    input.kbLayout = "@KB_LAYOUT@";
    monitor.scale = 1;
    theme = {
      default = "rose-pine";
      packs = [ "core" ]; # add "f1" for the F1 team themes
    };
    bar = {
      left = [ "workspaces" "windowTitle" ];
      center = [ "media" "clock" ]; # optional: "f1"
      right = [ "tray" "status" ]; # optional: "agentUsage"
    };
  };

  home.packages = with pkgs; [ ];
}
