# Trace

## 2026-04-20

- Purpose: Investigate why AwesomeWM autostart on Ubuntu aarch64 was not bringing up `redshift`.
- Did: Confirmed the autostart script prepended Linuxbrew to `PATH`, causing Awesome to pick `/home/linuxbrew/.linuxbrew/bin/redshift`; that build only exposes `dummy` mode, so it cannot drive the X11 display stack. Updated the Ubuntu ARM autostart script to resolve a usable `redshift` binary, added a regression check under `tests/`, created the required `memory/` and `logs/` project records, and synced the fixed script to `~/.config/awesome/autostart.sh`.
- Next: Re-login or restart Awesome from a fresh session to verify the color temperature changes; if needed, add the same binary-selection guard to other desktop autostart entry points that may call `redshift`.
- Purpose: Keep the original Awesome autostart script unchanged and solve the conflict by removing the Linuxbrew `redshift`.
- Did: Verified that uninstalling the brew formula is sufficient because the system `redshift` is already installed at `/usr/bin/redshift` and the brew formula has no installed dependents. Reverted the script-level workaround, removed the associated regression test, updated persistent notes to reflect the preference for environment cleanup over script hardening in this case, uninstalled the brew `redshift`, and synced the reverted autostart script back to `~/.config/awesome/autostart.sh`.
- Next: Restart Awesome or log in again to confirm autostart now launches the system `redshift`; if `redshift` still fails after logout/login, inspect the actual X session environment and `~/.xsession-errors` or Awesome logs rather than changing the script first.
- Purpose: Persist the redshift resolution changes to the repository and GitHub.
- Did: Reviewed the working tree to ensure only the Awesome autostart revert plus the new `memory/` and `logs/` records are included, then prepared the branch for commit and push on `main`.
- Next: Commit the tracked repo changes, push them to `origin/main`, and only revisit the Awesome script if a fresh login still fails to start `redshift`.
