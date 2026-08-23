-- ~/.config/hypr/hyprland.lua
-- Конфиг Hyprland (Lua-провайдер, Hyprland 0.56).
-- Документация: https://wiki.hypr.land/
-- После правки: hyprctl reload   (или SUPER + SHIFT + R)

------------------------------------------------------------
-- ПРОГРАММЫ
------------------------------------------------------------
local terminal    = "kitty"
local browser     = "google-chrome-stable"
local fileManager = "thunar"
local menu        = "wofi --show drun"
local home        = os.getenv("HOME")
local bin         = home .. "/.local/bin/"

------------------------------------------------------------
-- МОНИТОРЫ
------------------------------------------------------------
-- Встроенный экран ноутбука
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1200@60",
    position = "auto",
    scale    = 1,
})

-- Любой внешний монитор: своё родное разрешение, автоматически справа.
-- Переключение режимов (дублировать / только внешний / и т.д.) — SUPER + SHIFT + E
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

------------------------------------------------------------
-- АВТОЗАПУСК
------------------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")                            -- панель
    hl.exec_cmd("mako")                              -- уведомления
    -- Живые обои Wallpaper Engine: GUI стартует в трее и поднимает
    -- последний выбранный обой. Окно -- по клику на иконке в waybar.
    hl.exec_cmd("linux-wallpaperengine-gui --hidden")
    -- Откат на статичные обои: закомментируй строку выше и раскомментируй эту.
    -- hl.exec_cmd("swaybg -m fill -i " .. home .. "/Pictures/Wallpapers/nix-wallpaper-nineish-dark-gray.png")
    hl.exec_cmd("hypridle")                          -- гашение экрана/блокировка
    hl.exec_cmd("systemctl --user start hyprpolkitagent")  -- запросы прав
    hl.exec_cmd("nm-applet --indicator")             -- значок сети
    hl.exec_cmd("blueman-applet")                    -- значок Bluetooth
    hl.exec_cmd("wl-paste --type text --watch cliphist store")   -- история буфера
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- Японский ввод. Иконку fcitx5 в трее выключаем: язык и так показан
    -- отдельным индикатором, два одинаковых значка рядом ни к чему.
    hl.exec_cmd("fcitx5 -d -r --disable=notificationitem")
end)

------------------------------------------------------------
-- ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ
------------------------------------------------------------
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

------------------------------------------------------------
-- ВНЕШНИЙ ВИД
------------------------------------------------------------
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 0,
        col = {
            active_border   = { colors = { "rgba(7aa2f7ee)", "rgba(bb9af7ee)" }, angle = 45 },
            inactive_border = "rgba(414868aa)",
        },
        resize_on_border = true,     -- тянуть окна за край
        allow_tearing = false,
        layout = "dwindle",
    },

 decoration = {
    rounding = 4,
    rounding_power = 1,
    blur = {
      enabled = true,
      size = 10,
      passes = 3,
      new_optimizations = true,
      noise = 0.02,
      contrast = 1.0,
      brightness = 0.7,
      xray = false,
    },
  },
    animations = { enabled = true },

    dwindle = {
        -- (dwindle.pseudotile в 0.56 убран; псевдо-режим — SUPER + P)
        preserve_split = true,
    },

    master = { new_status = "master" },

    misc = {
        force_default_wallpaper = 0,      -- без аниме-обоев по умолчанию
        disable_hyprland_logo = true,
        -- (misc.vfr в 0.56 убран, VFR включён всегда)
        focus_on_activate = false,   -- не перетягивать фокус, когда программа просит внимания

        -- Погасший экран должен будиться клавишей и тачпадом.
        -- В 0.56 обе опции по умолчанию false, из-за чего чёрный экран
        -- нельзя было оживить ничем, кроме кнопки питания — а она усыпляла.
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,
    },
})

------------------------------------------------------------
-- АНИМАЦИИ (значения по умолчанию Hyprland)
------------------------------------------------------------
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

------------------------------------------------------------
-- ВВОД
------------------------------------------------------------
hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_options = "grp:alt_shift_toggle",   -- смена раскладки: Alt + Shift
        follow_mouse = 1,
        sensitivity = 0,
        numlock_by_default = true,
        touchpad = {
            natural_scroll = false,
            tap_to_click = true,        -- тап = клик
            disable_while_typing = true,
            scroll_factor = 0.6,
        },
    },
    cursor = {
        inactive_timeout = 5,           -- прятать курсор через 5 с
        hide_on_key_press = true,
    },
})

-- Жесты тачпада: три пальца в сторону — смена рабочего стола
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })

------------------------------------------------------------
-- ГОРЯЧИЕ КЛАВИШИ
------------------------------------------------------------
local mod = "SUPER"   -- клавиша Windows

-- Запуск программ
hl.bind(mod .. " + Return",     hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + T",          hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + B",          hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + E",          hl.dsp.exec_cmd(fileManager))
hl.bind(mod .. " + D",          hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + R",          hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + V",          hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
hl.bind(mod .. " + L",          hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + M",          hl.dsp.exec_cmd("wlogout"))

-- Управление окном
hl.bind(mod .. " + Q",          hl.dsp.window.close())
hl.bind(mod .. " + C",          hl.dsp.window.close())
hl.bind(mod .. " + F",          hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + SHIFT + F",  hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + SPACE",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",          hl.dsp.window.pseudo())
hl.bind(mod .. " + J",          hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + K",          hl.dsp.window.center())

-- Служебное
hl.bind(mod .. " + SHIFT + R",  hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + M",  hl.dsp.exit())
hl.bind(mod .. " + SHIFT + E",  hl.dsp.exec_cmd(bin .. "hypr-display"))   -- внешний монитор

-- Фокус и перемещение окон: стрелки
-- (hjkl не используются: J, K и L заняты togglesplit, центрированием и блокировкой)
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- Изменение размера окна: SUPER + ALT + стрелки
hl.bind(mod .. " + ALT + left",  hl.dsp.window.resize({ x = -60, y = 0,   relative = true }))
hl.bind(mod .. " + ALT + right", hl.dsp.window.resize({ x = 60,  y = 0,   relative = true }))
hl.bind(mod .. " + ALT + up",    hl.dsp.window.resize({ x = 0,   y = -60, relative = true }))
hl.bind(mod .. " + ALT + down",  hl.dsp.window.resize({ x = 0,   y = 60,  relative = true }))

-- Рабочие столы 1..10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,          hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,  hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + TAB",        hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + TAB",hl.dsp.focus({ workspace = "e-1" }))

-- Второй монитор: перенос фокуса и рабочего стола
hl.bind(mod .. " + COMMA",         hl.dsp.focus({ monitor = "-1" }))
hl.bind(mod .. " + PERIOD",        hl.dsp.focus({ monitor = "+1" }))
hl.bind(mod .. " + SHIFT + COMMA", hl.dsp.workspace.move({ monitor = "-1" }))
hl.bind(mod .. " + SHIFT + PERIOD",hl.dsp.workspace.move({ monitor = "+1" }))

-- Карман (scratchpad)
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Мышь: перетаскивание и размер
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Скриншоты
hl.bind("Print",           hl.dsp.exec_cmd("hyprshot -m region -o " .. home .. "/Pictures/Screenshots"))
hl.bind("SHIFT + Print",   hl.dsp.exec_cmd("hyprshot -m window -o " .. home .. "/Pictures/Screenshots"))
hl.bind("CTRL + Print",    hl.dsp.exec_cmd("hyprshot -m output -o " .. home .. "/Pictures/Screenshots"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprshot -m region -o " .. home .. "/Pictures/Screenshots"))

-- Громкость, яркость, музыка (работают и на заблокированном экране)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Режимы питания (performance / balanced / power-saver)
hl.bind(mod .. " + ALT + P", hl.dsp.exec_cmd(bin .. "power-mode next"))
hl.bind(mod .. " + ALT + 1", hl.dsp.exec_cmd(bin .. "power-mode power-saver"))
hl.bind(mod .. " + ALT + 2", hl.dsp.exec_cmd(bin .. "power-mode balanced"))
hl.bind(mod .. " + ALT + 3", hl.dsp.exec_cmd(bin .. "power-mode performance"))

-- Японский ввод. Сам переключатель — внутри fcitx5 (Ctrl+Space), поэтому бинд
-- помечен non_consuming: клавиша идёт дальше в fcitx5, а мы лишь просим
-- индикатор в панели перечитать состояние. Перехватить её здесь нельзя —
-- тогда fcitx5 её не увидит и переключать будет нечего.
hl.bind("CTRL + SPACE", hl.dsp.exec_cmd(bin .. "lang-poke"), { non_consuming = true })

-- Крышка ноутбука: если подключён внешний монитор — гасим встроенный экран,
-- а не уходим в сон (сон при одном экране делает logind).
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd(bin .. "hypr-lid close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(bin .. "hypr-lid open"),  { locked = true })

------------------------------------------------------------
-- ПРАВИЛА ОКОН
------------------------------------------------------------
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Небольшие утилиты — плавающими окнами
hl.window_rule({
    name = "float-utils",
    match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|org.gnome.Calculator|wdisplays|nwg-displays)$" },
    float = true,
})

-- Диалоги открытия/сохранения файлов
hl.window_rule({
    name = "float-dialogs",
    match = { title = "^(Open File|Save File|Открыть файл|Сохранить файл)" },
    float = true,
})

-- Видео «поверх всех окон» (picture-in-picture)
hl.window_rule({
    name = "pip",
    match = { title = "^(Picture-in-Picture|Картинка в картинке)$" },
    float = true,
    pin = true,
})
