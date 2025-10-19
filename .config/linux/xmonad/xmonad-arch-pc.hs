import XMonad

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.SetWMName

import XMonad.Util.EZConfig
import XMonad.Util.Loggers
import XMonad.Util.SpawnOnce
import XMonad.Util.Run (spawnPipe)
import System.IO
import System.Environment (setEnv)

import XMonad.Layout.Magnifier
import XMonad.Layout.ThreeColumns
import XMonad.Layout.Spacing

import qualified XMonad.StackSet as W

-- workspaces
myWorkspaces :: [String]
myWorkspaces = ["browser", "code", "note", "email", "other"]

-- trayer config string
myTrayerCmd :: String
myTrayerCmd = "killall trayer 2>/dev/null; sleep 0.1; \
  \trayer \
  \--edge top \
  \--align right \
  \--widthtype percent \
  \--width 10 \
  \--height 56 \
  \--SetDockType true \
  \--SetPartialStrut true \
  \--expand true \
  \--transparent true \
  \--alpha 80 \
  \--tint 0x282c34 \
  \--iconspacing 16 \
  \--distance 0"

-- Main entry point
main :: IO ()
main = do
    -- Set default editor
    setEnv "EDITOR" "nvim"
    setEnv "VISUAL" "nvim"
    xmproc <- spawnPipe "xmobar ~/.config/xmobar/xmobarrc"
    xmonad $ ewmhFullscreen $ ewmh $ docks $ def
        { modMask     = mod4Mask
        , workspaces  = myWorkspaces
        , layoutHook  = myLayout
        , manageHook  = myManageHook
        , terminal    = "alacritty"
        , startupHook = myStartupHook
        , logHook     = dynamicLogWithPP $ myXmobarPP { ppOutput = hPutStrLn xmproc }
        , borderWidth        = 2
        , normalBorderColor  = "#3e4451"
        , focusedBorderColor = "#61afef"
        }
      `additionalKeysP`
        [ ("M-S-z", spawn "betterlockscreen -l -u ~/Pictures/")
        , ("M-f"  , spawn "microsoft-edge-stable")
        , ("M-b"  , sendMessage ToggleStruts)
        , ("M-p"  , spawn "rofi -show drun")
        , ("M-<Return>", spawn "alacritty")
        , ("M-s", spawn "maim -s ~/.cache/com.pot-app.desktop/pot_screenshot_cut.png && curl '127.0.0.1:60828/ocr_translate?screenshot=false'")
        ]

-- Startup hook
myStartupHook :: X ()
myStartupHook = do
    setWMName "LG3D"  -- Fix for some Java applications
    spawn "feh --bg-fill --randomize ~/Pictures/*"
    spawn "xrdb -merge ~/.config/chadwm/.Xresources"
    spawn "killall dunst 2>/dev/null; sleep 0.1; dunst"
    spawn "killall Snipaste 2>/dev/null; sleep 0.2; Snipaste"
    spawn "killall fcitx5 2>/dev/null; sleep 0.1; fcitx5"
    spawn "killall picom 2>/dev/null; sleep 0.1; picom --config ~/.config/picom/picom.conf"
    spawn "killall -9 redshift 2>/dev/null; sleep 1; redshift -l 30.6:114.3 -t 6500:5000"
    spawn myTrayerCmd
    -- spawn "killall nm-applet 2>/dev/null; sleep 0.1; nm-applet" -- network manager
    spawn "killall pasystray 2>/dev/null; sleep 0.1; pasystray"
    spawn "killall blueman-applet 2>/dev/null; sleep 0.1; blueman-applet"
    spawn "killall udiskie 2>/dev/null; sleep 0.1; udiskie -t" -- auto mount udisk
    spawn "killall pot 2>/dev/null; sleep 0.1; pot"

-- Window management rules
myManageHook :: ManageHook
myManageHook = composeAll
    [ className =? "Snipaste"  --> doFloat
    , className =? "Pot"  --> doFloat
    , isDialog                 --> doFloat
    ] <+> manageDocks

-- Layout configuration
myLayout = avoidStruts (tiled ||| Mirror tiled ||| Full ||| threeCol)
  where
    threeCol = magnifiercz' 1.3 $ ThreeColMid nmaster delta ratio
    tiled    = Tall nmaster delta ratio
    nmaster  = 1
    ratio    = 1/2
    delta    = 3/100

-- xmobar status bar appearance configuration
myXmobarPP :: PP
myXmobarPP = def
    { ppSep             = magenta " • "
    , ppTitleSanitize   = xmobarStrip
    , ppCurrent         = filterWS $ wrap " " "" . xmobarBorder "Top" "#61afef" 2
    , ppVisible         = filterWS $ wrap " " "" . blue
    , ppHidden          = filterWS $ white . wrap " " ""
    , ppHiddenNoWindows = filterWS $ lowWhite . wrap " " ""
    , ppUrgent          = filterWS $ red . wrap (yellow "!") (yellow "!")
    , ppOrder           = \[ws, l, _, wins] -> [ws, l, wins]
    , ppExtras          = [logTitles formatFocused formatUnfocused]
    }
  where
    -- use myWorkspace
    filterWS f ws = if ws `elem` myWorkspaces then f ws else ""
    formatFocused   = wrap (white "[") (white "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow

    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta  = xmobarColor "#c678dd" ""
    blue     = xmobarColor "#61afef" ""
    white    = xmobarColor "#abb2bf" ""
    yellow   = xmobarColor "#e5c07b" ""
    red      = xmobarColor "#e06c75" ""
    lowWhite = xmobarColor "#565c64" ""