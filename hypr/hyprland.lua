-- ~/.config/hypr/hyprland.lua
-- Hyprland 0.55+ Lua configuration
-- Refer to https://wiki.hypr.land/Configuring/Start/

-- Read persisted Catppuccin mode (written by sync-theme.sh)
local function read_mode()
    local f = io.open(os.getenv("HOME") .. "/.cache/catppuccin-mode", "r")
    if not f then return "mocha" end
    local m = f:read("*l"); f:close()
    return (m == "latte") and "latte" or "mocha"
end
local mode = read_mode()

local palette = {
    mocha = { active = "rgba(cba6f7ff)", inactive = "rgba(45475aff)", shadow = "rgba(11111bcc)" },
    latte = { active = "rgba(8839efff)", inactive = "rgba(bcc0ccff)", shadow = "rgba(dce0e8aa)" },
}
local pal = palette[mode]


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- MSI gaming monitor on DP-1
-- 240 Hz, HDR (BT.2020 wide gamut + PQ transfer), 10-bit, VRR mode 3
-- VRR modes: 0 = off | 1 = always | 2 = fullscreen only | 3 = fullscreen (content-type aware)
-- NOTE: verify the resolution below matches your panel — common MSI QHD: 2560x1440
--       run `hyprctl monitors` to see what Hyprland detects for DP-1
hl.monitor({
    output    = "DP-1",
    mode      = "2560x1440@240",
    position  = "0x0",
    scale     = 1,

    -- 10-bit colour depth is required for HDR
    bitdepth  = 10,

    -- cm = "hdr"  →  wide colour gamut (BT.2020 primaries) + HDR PQ transfer function
    cm        = "hdr",

    -- SDR app brightness/saturation inside HDR mode (1.0 = unchanged)
    -- Raise sdrbrightness toward 1.5-2.0 if SDR content looks too dim on your panel
    sdrbrightness  = 1.0,
    sdrsaturation  = 1.0,
    sdr_min_luminance = 0,
    sdr_max_luminance = 1000,

    -- VRR mode 3: auto-enables adaptive sync for fullscreen game/video content
    vrr       = 3,
})

-- Samsung LF24T35 on HDMI-A-1
-- 1080p SDR monitor, 99% sRGB gamut — srgb is the correct colour space
-- Portrait flipped (transform 3 = 270°), positioned left of DP-1
-- Effective portrait dimensions are 1080×1920, so x = -1080 sits flush left of DP-1
hl.monitor({
    output    = "HDMI-A-1",
    mode      = "1920x1080@75",
    position  = "-1080x0",
    scale     = 1,
    transform = 3,
    cm        = "srgb",
})

-- Fallback rule for any other display plugged in
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "env DRI_PRIME=0 kitty"
local launcher = "qs -c config ipc call launcher toggle"


-----------------------------
---- ENVIRONMENT VARIABLES --
-----------------------------

hl.env("XCURSOR_SIZE",          "24")
hl.env("HYPRCURSOR_SIZE",       "24")

-- Catppuccin cursor theme — matches mocha/latte mode
local cursor_theme = (mode == "latte") and "catppuccin-latte-mauve-cursors" or "catppuccin-mocha-dark-cursors"
hl.env("XCURSOR_THEME",    cursor_theme)
hl.env("HYPRCURSOR_THEME", cursor_theme)

-- Qt theming — use Kvantum style, configured via qt5ct/qt6ct
hl.env("QT_QPA_PLATFORMTHEME",  "qt5ct")
hl.env("QT_STYLE_OVERRIDE",     "kvantum")

-- GTK theming — ensure apps pick up the correct icon theme
hl.env("ICON_THEME",            (mode == "latte") and "Papirus" or "Papirus-Dark")


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- hyprpaper, hypridle, hyprpolkitagent are managed by systemd user services
-- (enabled via uwsm/graphical-session.target) — no need to exec them here.
local function apply_cursor()
    hl.exec_cmd("hyprctl setcursor " .. cursor_theme .. " 24")
    hl.exec_cmd("systemctl --user set-environment XCURSOR_THEME=" .. cursor_theme ..
                " XCURSOR_SIZE=24 HYPRCURSOR_THEME=" .. cursor_theme .. " HYPRCURSOR_SIZE=24")
end

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE")
    apply_cursor()
    hl.exec_cmd("quickshell -c config")
end)

-- Re-apply on every config reload (cursor resets to default on reload).
hl.on("config.reloaded", apply_cursor)


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- See https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = pal.active,
            inactive_border = pal.inactive,
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 16,
        rounding_power = 2.0,

        active_opacity   = 1.0,
        inactive_opacity = 0.95,

        shadow = {
            enabled      = true,
            range        = 24,
            render_power = 3,
            color        = pal.shadow,
        },

        blur = {
            enabled  = true,
            size     = 10,
            passes   = 3,
            vibrancy = 0.05,
            popups   = true,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Bezier curves — see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("smoothOut",  { type = "bezier", points = { {0.36, 0},    {0.66, -0.56} } })
hl.curve("smoothIn",   { type = "bezier", points = { {0.25, 1},    {0.5,  1}     } })
hl.curve("overshot",   { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.05}  } })
hl.curve("linear",     { type = "bezier", points = { {0,    0},    {1,    1}     } })

-- Animations
hl.animation({ leaf = "windows",     enabled = true, speed = 4,   bezier = "overshot",  style = "slide"     })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4,   bezier = "overshot",  style = "slide"     })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4,   bezier = "smoothOut", style = "slide"     })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,   bezier = "smoothIn"                       })
hl.animation({ leaf = "border",      enabled = true, speed = 5,   bezier = "linear"                         })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,   bezier = "linear",    style = "loop"      })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 4,   bezier = "smoothIn"                       })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 4,   bezier = "smoothOut"                      })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,   bezier = "overshot",  style = "slidevert" })


-------------------
---- LAYOUTS ------
-------------------

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        animate_manual_resizes  = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_options = "caps:escape",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
            tap_to_click   = true,
            drag_lock      = true,
        },
    },
})

-- Workspace swipe gesture (3-finger horizontal)
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Applications
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + C",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exit())
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(terminal .. " -e ranger"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + W",      hl.dsp.exec_cmd("quickshell -c config ipc call wallpaper toggle"))

-- Window management
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))  -- dwindle only

-- Move focus — vim keys
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down"  }))

-- Move windows — vim keys
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left"  }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up"    }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down"  }))

-- Resize windows — vim keys (repeating)
hl.bind(mainMod .. " + ALT + H", hl.dsp.window.resize({ x = -40, y = 0   }), { repeating = true })
hl.bind(mainMod .. " + ALT + L", hl.dsp.window.resize({ x = 40,  y = 0   }), { repeating = true })
hl.bind(mainMod .. " + ALT + K", hl.dsp.window.resize({ x = 0,   y = -40 }), { repeating = true })
hl.bind(mainMod .. " + ALT + J", hl.dsp.window.resize({ x = 0,   y = 40  }), { repeating = true })

-- Workspaces
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,            hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,    hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces with mouse wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows by dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media / volume keys
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"),    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"),    { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"),   { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),                        { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),                              { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),                          { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +5%"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"),   { locked = true, repeating = true })

-- Screenshot
hl.bind("Print",         hl.dsp.exec_cmd("grimblast copy area"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grimblast copy screen"))


--------------------
---- WORKSPACES ----
--------------------

-- Workspaces 1-5 on main (DP-1), 6-9 on secondary (HDMI-A-1), all persistent
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true, monitor = "DP-1" })
end
for i = 6, 9 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true, monitor = "HDMI-A-1" })
end


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Suppress maximize requests from all apps
hl.window_rule({
    name          = "suppress-maximize",
    match         = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix XWayland drag issues
hl.window_rule({
    name       = "fix-xwayland-drag",
    match      = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus   = true,
})

-- Float specific apps
hl.window_rule({ match = { class = "pavucontrol"         }, float = true })
hl.window_rule({ match = { class = "nm-connection-editor"}, float = true })
hl.window_rule({ match = { class = "blueman-manager"     }, float = true })
hl.window_rule({ match = { title = "^Open File"          }, float = true })
hl.window_rule({ match = { title = "^Save As"            }, float = true })

-- Kitty transparency
hl.window_rule({
    match   = { class = "kitty" },
    opacity = "0.92 0.85",
})

-- No blur on quickshell layer — blur only works on SDR monitors (not HDR/DP-1),
-- causing an asymmetric frosted effect on HDMI-A-1. Bar uses its own opacity instead.

