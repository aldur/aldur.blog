---
title: 'QoL: Smart select around single quotes in iTerm'
date: 2025-01-12
redirect_from: /articles/2025/01/12/qol-selecting-around-single-quotes-in-iterm.html
excerpt: >
  Fixing iTerm's smart selection for single quotes
---

<div class="video-container">
  <video class="responsive-video" autoplay="autoplay" loop="loop">
    <source src="{% link uploads/iTerm_single_quotes.webm %}" type="video/webm">
    Your browser does not support the video tag.
  </video>
  <p class="video-caption" markdown="1">
    _tl;dw: double click around single quotes to select_
  </p>
</div>

<div class="note" markdown="1">
QoL: Quality of Life improvements.

Sharpening the axe is useful (and rewarding) and 1% improvements compound.

</div>

I have used the iTerm terminal emulator for years, for as long as I remember
using macOS. Its "[Smart Selection][0]" feature
enables double-clicking[^double_click] on text to semantically select it (e.g., URLs, email
addresses, text wrapped by double quotes, etc.).

Smart Selection is super nice, but by default does not work for text within
single quotes. To fix that:

1. Open your iTerm settings
1. → Profiles (tab)
1. → Advanced (tab)
1. → Smart Selection
1. → Click on "+"
1. Use "Single quoted string" or any description you'd like, then
   `@?'(?:[^'\\]|\\.)*'` as the regular expression.

[0]: https://iterm2.com/documentation-smart-selection.html

#### Footnotes

[^double_click]:
    By default is configured to smart-select on quadruple-click,
    but you can change that to double click in General/Selection.

