---
title: 'TIL: Faster ChromeOS animations'
date: 2026-10-31
tags: [ChromeOS, TIL]
---

Today I learned how to enable faster animations on ChromeOS, a bit hackishly:

1. Enable `chrome://flags/#ash-debug-shortcuts`.
1. Summon the debug menu with
   <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>.
1. From the settings tab (cog icon in the top left), decrease animation speed
   to 0x or 0.5x.

<div class="video-container">
  <video class="responsive-video" autoplay loop controls muted playsinline
         poster="{% link images/faster-chromeos-animations.webp %}"
         aria-label="Change the ChromeOS animation speed in the debug menu">
    <source src="{% link uploads/faster-chromeos-animations.mp4 %}" type="video/mp4">
    <a href="{% link uploads/faster-chromeos-animations.mp4 %}">Download the video.</a>
  </video>
  <p class="video-caption">Setting the animation speed in the debug menu and seeing the speed difference.</p>
</div>
