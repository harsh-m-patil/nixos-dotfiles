{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "26.11";

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_IN";

  users.users.harshmpatil.description = "harshmpatil";

  services = {
    xserver.enable = true;
    desktopManager.gnome.enable = true;
    printing.enable = true;
  };

  programs = {
    firefox.enable = true;
    nix-ld.enable = true;
    obs-studio.enable = true;
  };

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;

  # System-wide fallback editor for root/recovery; user tools live in home.nix.
  environment.systemPackages = [ pkgs.vim ];

  fonts.packages = [ pkgs.lilex ];

  nix.settings.warn-dirty = false;
}
