# Organizing Preferences

- On Ubuntu aarch64, X11-sensitive desktop tools should prefer system binaries over Linuxbrew when both exist, especially `redshift`.
- When a Linuxbrew package shadows a working system binary and is not needed elsewhere, prefer removing the package over adding defensive logic to the autostart script.
- For window-manager helper scripts invoked via `~/.config/scripts/*`, prefer always installing the script and preserving its executable bit even when the runtime backend is not yet installed.
