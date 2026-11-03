hl.on("hyprland.start", function ()
  -- Plain Hyprland (non-uwsm): portal needs graphical-session.target for OBS PipeWire capture.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
  hl.exec_cmd("systemctl --user start nixos-fake-graphical-session.target")
  hl.exec_cmd("systemctl --user start xdg-desktop-portal.service")

  hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
  hl.exec_cmd("swaybg -i ~/Walls/.theme-wallpaper -m fill")
  hl.exec_cmd("vicinae server")
  hl.exec_cmd("qs -d")
end)
