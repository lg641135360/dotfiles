# Trace

## 2026-04-20

- Purpose: Persist the AwesomeWM lock-screen fix and its regression coverage to GitHub.
- Did: Reviewed the lock-script fallback, installer executable-bit repair, the new `tests/awesome_lock_test.sh`, and the updated memory/trace records, then prepared the tracked changes on `main` for commit and push.
- Next: Commit the lock-screen fix set to `main`, push it to `origin/main`, and only revisit the new `tests/` directory if the repository policy later changes to disallow lightweight shell regression tests.

- Purpose: Fix the AwesomeWM lock script on Ubuntu aarch64 so the configured shortcut/button can actually execute and work with the system `i3lock`.
- Did: Traced the lock path from Awesome bindings and wibar to `~/.config/scripts/lock`, confirmed the script was not installed when `i3lock` was absent, then found a second deployment bug where an already-copied script kept the wrong `0644` mode because `install.sh` skipped identical-content files without checking executable-bit drift. Updated `.config/scripts/lock` to fall back to plain `i3lock` when `--blur` is unsupported, changed `install.sh` to always install the lock script and to recopy identical-content files when executable bits differ, added regression coverage under `tests/awesome_lock_test.sh`, set the repo script executable, re-ran the installer, and verified `/home/rikoo/.config/scripts/lock` is now mode `775` with `/usr/bin/i3lock` present.
- Next: If idle or suspend-triggered auto-lock is desired, add `xss-lock` or `xautolock` to the Ubuntu aarch64 Awesome autostart path; otherwise manual lock via `Mod+Ctrl+l` should now work without further config changes.

- Purpose: Investigate why AwesomeWM autostart on Ubuntu aarch64 was not bringing up `redshift`.
- Did: Confirmed the autostart script prepended Linuxbrew to `PATH`, causing Awesome to pick `/home/linuxbrew/.linuxbrew/bin/redshift`; that build only exposes `dummy` mode, so it cannot drive the X11 display stack. Updated the Ubuntu ARM autostart script to resolve a usable `redshift` binary, added a regression check under `tests/`, created the required `memory/` and `logs/` project records, and synced the fixed script to `~/.config/awesome/autostart.sh`.
- Next: Re-login or restart Awesome from a fresh session to verify the color temperature changes; if needed, add the same binary-selection guard to other desktop autostart entry points that may call `redshift`.
- Purpose: Keep the original Awesome autostart script unchanged and solve the conflict by removing the Linuxbrew `redshift`.
- Did: Verified that uninstalling the brew formula is sufficient because the system `redshift` is already installed at `/usr/bin/redshift` and the brew formula has no installed dependents. Reverted the script-level workaround, removed the associated regression test, updated persistent notes to reflect the preference for environment cleanup over script hardening in this case, uninstalled the brew `redshift`, and synced the reverted autostart script back to `~/.config/awesome/autostart.sh`.
- Next: Restart Awesome or log in again to confirm autostart now launches the system `redshift`; if `redshift` still fails after logout/login, inspect the actual X session environment and `~/.xsession-errors` or Awesome logs rather than changing the script first.
- Purpose: Persist the redshift resolution changes to the repository and GitHub.
- Did: Reviewed the working tree to ensure only the Awesome autostart revert plus the new `memory/` and `logs/` records are included, then prepared the branch for commit and push on `main`.
- Next: Commit the tracked repo changes, push them to `origin/main`, and only revisit the Awesome script if a fresh login still fails to start `redshift`.
