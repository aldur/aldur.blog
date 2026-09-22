---
title: 'Sunsetting my Hammerspoon emoji chooser'
date: 2025-07-14
---

One of the things I love about writing software for myself is the very low risk
of [enshittification](https://en.wikipedia.org/wiki/Enshittification). The
product will change only if I want it to change. I typically iterate on it
early on and then simply enjoy using it when stable. 

By  having code for _exactly_ what I need and nothing more, I can get away with
minimal dependencies and moving parts. By building on opensource foundations,
self-made software typically requires very little maintenance as well.

Then, one day I look back and discover that I have been using that software for
almost a decade. That is certainly the case for my
[Hammerspoon emoji chooser on macOS](../_posts/2016-12-19-hammerspoon-emojis.md),
dated December 2016. I used it daily on countless chats and only occasionally
updated it to support new Unicode symbols.

At the time, I built it because I could not find an alternative good enough for
me: with keyboard only navigation, escape to dismiss, quick searching,
hackable. I remember _knowing_ that macOS shipped with an emoji picker, but I
was not fond of it -- it felt clumsy and had only partial keyboard application.

At some point, macOS' emoji picker must have improved. Today, it feels good
enough for my needs. It has a default keybinding to
<kbd>🌐︎</kbd>+<kbd>E</kbd> (using Apple's relatively new "Globe"
key), it focuses the search bar, and <kbd>Enter</kbd> accepts selection. That
compares pretty nicely to how I set up my emoji chooser, bound to
<kbd>Hyper</kbd>+<kbd>E</kbd> (with <kbd>Hyper</kbd> set to
<kbd>⌃ Control</kbd> + <kbd>⌥ Option</kbd> + <kbd>⌘ Command</kbd>).

{:.text-align-center}
![[The built-in macOS emoji picker with the query "hello"]](../images/builtin_emoji_picker.webp){:.centered style="width: calc(784px/2); height: calc(892px/2);"}
_Hello from the built-in macOS picker_

That's why it is (sad) time to sunset my own implementation. When possible, I
strive for minimalism and try sticking to provided defaults. By using the
built-in picker I can disable Hammerspoon's accessibility access (required to
type the emoji into the corresponding window) and remove one more service from
my stack. If Apple ever messes it up, I can always get my self-made version
back in no time. If you ever need it, you will find it archived {% include
github_link.html
url="https://github.com/aldur/dotfiles/tree/49b03cee63c52be55d92723ee9d583d51f90f81d/osx/hammerspoon/Spoons/Emojis.spoon"
text="at this permalink" -%}.

