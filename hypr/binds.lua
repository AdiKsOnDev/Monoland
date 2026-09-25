local terminal = "kitty"
local browser = "zen-browser"
local fileManager = "dolphin"
local referenceManager = "zotero"
local menu = "quickshell ipc call launcher open"
local powerMenu = "quickshell ipc call powermenu open"
local scriptPath = os.getenv("HOME") .. "/.local/share/bin"
local mainMod = "SUPER"

hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("quickshell ipc call lockscreen lock"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("quickshell ipc call clipboard open"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close({}))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(referenceManager))
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + BackSpace", hl.dsp.exec_cmd(powerMenu))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("obsidian"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("Telegram"))

for key, direction in pairs({ left = "left", right = "right", up = "up", down = "down" }) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end

hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(scriptPath .. "/screenshot.sh s"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd(scriptPath .. "/screenshot.sh sf"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd(scriptPath .. "/screenshot.sh m"))
hl.bind("Print", hl.dsp.exec_cmd(scriptPath .. "/screenshot.sh p"))

hl.bind(mainMod .. " + K", hl.dsp.exec_cmd(scriptPath .. "/keyboardSwitch.sh"))

local resizeBinds = {
    I = { x = 0, y = 150 },
    K = { x = 0, y = -150 },
    J = { x = -150, y = 0 },
    L = { x = 150, y = 0 },
}

for key, offset in pairs(resizeBinds) do
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.resize({
        x = offset.x,
        y = offset.y,
        relative = true,
    }))
end

for key, direction in pairs({ Up = "up", Down = "down", Left = "left", Right = "right" }) do
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }))

for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind(mainMod .. " + CTRL + Right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + Left", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CTRL + SHIFT + Right", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + SHIFT + Left", hl.dsp.window.move({ workspace = "r-1" }))

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

local repeatingLockedBinds = {
    XF86AudioRaiseVolume = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+",
    XF86AudioLowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    XF86AudioMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    XF86AudioMicMute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
    XF86MonBrightnessUp = "brightnessctl -e4 -n2 set 5%+",
    XF86MonBrightnessDown = "brightnessctl -e4 -n2 set 5%-",
}

for key, command in pairs(repeatingLockedBinds) do
    hl.bind(key, hl.dsp.exec_cmd(command), { locked = true, repeating = true })
end

local lockedBinds = {
    XF86AudioNext = "playerctl next",
    XF86AudioPause = "playerctl play-pause",
    XF86AudioPlay = "playerctl play-pause",
    XF86AudioPrev = "playerctl previous",
}

for key, command in pairs(lockedBinds) do
    hl.bind(key, hl.dsp.exec_cmd(command), { locked = true })
end

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
