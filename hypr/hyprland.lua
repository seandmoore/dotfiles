-- ~/.config/hypr/hyprland.lua
-- Hyprland 0.55+ Lua configuration — Catppuccin Mocha
-- Refer to https://wiki.hypr.land/Configuring/Start/

-- Split into multiple files with require() for larger setups:
-- require("binds")
-- require("rules")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "kitty"
local launcher = "qs ipc call launcher toggle"


-----------------------------
---- ENVIRONMENT VARIABLES --
-----------------------------

hl.env("XCURSOR_SIZE",     "24")
hl.env("HYPRCURSOR_SIZE",  "24")


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("quickshell")
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- See https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        -- Catppuccin Mocha — Mauve active, Surface1 inactive
        col = {
            active_border   = "rgba(cba6f7ff)",
            inactive_border = "rgba(45475aff)",
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
            color        = "rgba(11111bcc)",
        },

        blur = {
            enabled  = true,
            size     = 10,
            passes   = 3,
            vibrancy = 0.1696,
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
        pseudotile     = true,
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
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(terminal .. " -e ranger"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("firefox"))

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
    opacity = { active = 0.92, inactive = 0.85 },
})

-- Quickshell layer rules
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Blur/
hl.layer_rule({ match = { namespace = "quickshell" }, blur        = true })
hl.layer_rule({ match = { namespace = "quickshell" }, ignore_zero = true })
