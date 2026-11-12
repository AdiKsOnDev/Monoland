hl.window_rule({
    name = "zen-opacity",
    match = {
        class = "zen",
    },
    opacity = "1 override",
})

hl.window_rule({
    name = "telegram-opacity",
    match = {
        class = "^(.*telegram.*)$",
    },
    opacity = "1 override",
})

hl.window_rule({
    name = "slack-opacity",
    match = {
        class = "slack",
    },
    opacity = "1 override",
})

hl.window_rule({
    name = "t3-code-opacity",
    match = {
        class = "^(.*t3.*)$",
    },
    opacity = "1 override",
})
