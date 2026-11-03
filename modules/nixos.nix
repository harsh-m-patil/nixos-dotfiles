{ config, lib, pkgs, ... }:

let
  cfg = config.dotfiles;
in
{
  options.dotfiles = {
    enable = lib.mkEnableOption "the Hyprland + Quickshell desktop" // { default = true; };

    user = lib.mkOption {
      type = lib.types.str;
      description = "Login user that gets the desktop (home-manager config is attached to this user).";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Groups added to the user on top of networkmanager, wheel, video and audio.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "video" "audio" ] ++ cfg.extraGroups;
      shell = pkgs.zsh;
    };

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    # Quickshell is the bar; waybar would also autostart with graphical-session.target.
    programs.waybar.enable = false;
    programs.zsh.enable = true;

    services.displayManager.gdm.enable = lib.mkDefault true;
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    security.rtkit.enable = true;
    networking.networkmanager.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    services.blueman.enable = lib.mkDefault config.hardware.bluetooth.enable;

    # Everything the bar, keybinds and theme scripts call at runtime.
    environment.systemPackages = with pkgs; [
      git
      stow
      jq
      python3
      ghostty
      starship
      fastfetch
      swaybg
      hyprlock
      hyprshot
      hyprpicker
      grim
      slurp
      wl-clipboard
      brightnessctl
      playerctl
      wireplumber
      lm_sensors
      cava
    ];

    fonts.packages = with pkgs; [
      geist-font
      nerd-fonts.jetbrains-mono
      nerd-fonts.geist-mono
    ];

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = true;
    };
    nix.gc = {
      automatic = lib.mkDefault true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
