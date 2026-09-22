---
layout: post
title: macOS Emoji Chooser with Hammerspoon
excerpt: >
    Search and select emojis by name with Hammerspoon.
last_modified_at: 2025-07-14
categories: [articles]
tags: [hammerspoon, emoji]
---

<div class="hint" markdown="1"> 
🌅 After 9 years of honorable service and
[updates](https://github.com/aldur/dotfiles/commit/14b11f24a54a0d799f69dcf0da65cb34d15e35a5)
all the way to [Unicode 15
emojis](https://unicode.org/emoji/charts-15.0/emoji-released.html) 🪼, it has
come time to sunset this in favor of the [built-in macOS picker](../_micros/sunsetting-my-hammerspoon-emoji-chooser.md).

You will find its last version archived {% include
github_link.html
url="https://github.com/aldur/dotfiles/tree/49b03cee63c52be55d92723ee9d583d51f90f81d/osx/hammerspoon/Spoons/Emojis.spoon"
text="at this permalink" -%}.
</div>

I use the awesome [Hammerspoon](https://github.com/Hammerspoon/hammerspoon) to
automate things on macOS. Today we'll see how to create an interactive emoji
search-engine to pick emojis by using their name or a few keywords:

{:.text-align-center}
![emoji-chooser](../images/emoji-chooser.webp){:.centered}
*Smile and say cheese!*

## Preliminary setup

To begin, download [this archive](../uploads/emojis.zip) and unzip into your
`~/.hammerspoon` directory. The archive contains a few thousands emojis in
`PNG` format and a `JSON` file encoding their details. I generated it through
[this script](https://gist.github.com/aldur/6b591c582db8a9134f31263f95cccfc2).

## Hammerspoon setup

Now, to Hammerspoon to load the emojis and build the search engine. We'll use
`hs.chooser` to create a Spotlight-like window that allows filtering and
selecting data. We'll populate it with emojis; once selected, the emoji will be
copied to clipboard and "typed" in the focused application.

Copy and paste the following snippet in your `init.lua` file:

```lua
-- Build the list of emojis to be displayed.
local choices = {}
for _, emoji in ipairs(hs.json.decode(io.open("emojis/emojis.json"):read())) do
    table.insert(choices,
        {text=emoji['name'],
            subText=table.concat(emoji['kwds'], ", "),
            image=hs.image.imageFromPath("emojis/" .. emoji['id'] .. ".png"),
            chars=emoji['chars']
        })
end

-- Focus the last used window.
local function focusLastFocused()
    local wf = hs.window.filter
    local lastFocused = wf.defaultCurrentSpace:getWindows(wf.sortByFocusedLast)
    if #lastFocused > 0 then lastFocused[1]:focus() end
end

-- Create the chooser.
-- On selection, copy the emoji and type it into the focused application.
local chooser = hs.chooser.new(function(choice)
    if not choice then focusLastFocused(); return end
    hs.pasteboard.setContents(choice["chars"])
    focusLastFocused()
    hs.eventtap.keyStrokes(hs.pasteboard.getContents())
end)

chooser:searchSubText(true)
chooser:choices(choices)
```

If you want, you can also customize the appearance of the chooser:

```lua
chooser:rows(5)
chooser:bgDark(true)
```

Lastly, bind the chooser to any key you like:

```lua
hs.hotkey.bind({"cmd", "alt"}, "E", function() chooser:show() end)
```

## Full result

You'll find:

- The complete result
  [here](https://github.com/aldur/dotfiles/tree/master/osx/hammerspoon/Spoons/Emojis.spoon).
- My full Hammerspoon configuration
  [here](https://github.com/aldur/dotfiles/tree/master/osx/hammerspoon).
