local input = hypr_module("settings").input

hl.config({
    input = {
        kb_layout  = input.kbLayout,
        kb_variant = input.kbVariant,
        kb_model   = "",
        kb_options = input.kbOptions,
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = input.sensitivity, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = input.naturalScroll,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})
