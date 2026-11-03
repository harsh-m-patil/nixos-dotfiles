{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "26.11";

  networking.wireless.enable = true; # wpa_supplicant
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_IN";

  users.users.harshmpatil.description = "harshmpatil";

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };
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
  environment.systemPackages = with pkgs; [
    vim
    neovim
    tmux
    kitty
    zoxide
    code-cursor
    gnumake
    tree-sitter
    gcc
    pulseaudio
    hyprpaper
    rustup
    cargo
    rust-analyzer
    chafa
    opencode
    mpv
    ripgrep
    fd
    fzf
    btop
    cursor-cli
    ffmpeg
    chromium
    nodejs
    pnpm
    gh
    t3code
  ];

  fonts.packages = with pkgs; [ lilex ];

  nix.settings.warn-dirty = false;
}
