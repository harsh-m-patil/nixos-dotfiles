{ pkgs, ... }:

# Machine-level settings. The desktop itself comes from modules/nixos.nix.
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "@TIMEZONE@";
  i18n.defaultLocale = "@LOCALE@";

  nixpkgs.config.allowUnfree = true;

  # Your own system packages.
  environment.systemPackages = with pkgs; [
    firefox
    neovim
  ];

  # Set once at install; do not change after (see `man configuration.nix`).
  system.stateVersion = "@STATE_VERSION@";
}
