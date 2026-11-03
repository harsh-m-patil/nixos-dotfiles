{ pkgs, ... }:

{
	home.stateVersion = "25.05";
	home.file = {
		".zshrc".source = ../../config/.zshrc;
		".zsh_aliases".source = ../../config/.zsh_aliases;
	};

	dotfiles.settings = {
		apps.browser = "chromium";
		monitor.scale = 1.25;
		theme = {
			default = "f1-mercedes";
			packs = [ "core" "f1" ];
		};
		bar = {
			left = [ "workspaces" "windowTitle" ];
			center = [ "media" "clock" "f1" ];
			right = [ "agentUsage" "tray" "status" ];
		};
	};

	programs.tmux = {
		enable = true;
		terminal = "tmux-256color";
		keyMode = "vi";
		mouse = true;
		prefix = "C-Space";
		baseIndex = 1;
		escapeTime = 0;
		historyLimit = 10000;
		customPaneNavigationAndResize = false; # handled by vim-tmux-navigator

		plugins = with pkgs.tmuxPlugins; [
			sensible
			vim-tmux-navigator
			yank
			tmux-floax
			rose-pine
		];

		extraConfig = ''
			# true color
			set-option -sa terminal-overrides ",xterm*:Tc"
			set -g extended-keys on
			set -g detach-on-destroy off
			set -as terminal-features ',xterm*:RGB'

			# secondary prefix
			set -g prefix2 C-@
			bind C-Space send-prefix
			bind C-@ send-prefix

			# Shift arrow to switch windows
			bind -n S-Left previous-window
			bind -n S-Right next-window

			# Alt vim keys to switch windows
			bind -n M-H previous-window
			bind -n M-L next-window

			# vi-mode keybindings
			bind-key -T copy-mode-vi v send-keys -X begin-selection
			bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
			bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
			bind-key x kill-pane

			# Start windows and panes at 1
			set -g pane-base-index 1
			set-option -g renumber-windows on
			bind h split-window -v -c "#{pane_current_path}"
			bind v split-window -h -c "#{pane_current_path}"

			# sesh session switcher
			bind-key K run-shell "sesh connect \"$(
				sesh list --icons | fzf-tmux -p 80%,70% \
					--no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
					--header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
					--bind 'tab:down,btab:up' \
					--bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
					--bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
					--bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
					--bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
					--bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
					--bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
					--preview-window 'right:55%' \
					--preview 'sesh preview {}'
			)\""

			# Rosé Pine (main) — matches quickshell Theme.qml
			set -g @rose_pine_variant main
		'';
	};

	home.packages = with pkgs; [
		# editors & terminal
		neovim
		kitty
		zoxide
		chafa
		btop
		sesh
		fzf # provides fzf-tmux
		fd
		ripgrep

		# development (rustup provides cargo, rustc and rust-analyzer)
		gnumake
		gcc
		tree-sitter
		rustup
		nodejs
		pnpm
		gh

		# AI / editors
		code-cursor
		cursor-cli
		opencode
		t3code
		(callPackage ../../packages/grok-bot { })

		# desktop & media
		chromium
		mpv
		ffmpeg
		hyprpaper
		pulseaudio # pactl
	];

	# shared-mime-info uses video/matroska for .mkv; mpv.desktop only lists video/x-matroska.
	xdg.mimeApps = {
		enable = true;
		defaultApplications = {
			"video/matroska" = "mpv.desktop";
			"video/x-matroska" = "mpv.desktop";
			"video/mkv" = "mpv.desktop";
			"x-scheme-handler/grokbot" = "grok-bot.desktop";
			"x-scheme-handler/sand" = "grok-bot.desktop";
		};
	};
}
