{ pkgs, ... }:

# Machine-level settings. The desktop itself comes from modules/nixos.nix.
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "@TIMEZONE@";
  i18n.defaultLocale = "@LOCALE@";

  nixpkgs.config.allowUnfree = true;

  programs.firefox.enable = true;

  # Only system-level tools here; user packages go in home.nix.
  environment.systemPackages = with pkgs; [ vim ];

  # Set once at install; do not change after (see `man configuration.nix`).
  system.stateVersion = "@STATE_VERSION@";
}
