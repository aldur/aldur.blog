---
title: 'TIL: chrome://device-log'
date: 2026-10-18
tags: [ChromeOS]
---

Today I learned that navigating to `chrome://device-log` pretty prints
structured logs in ChromeOS. Claude suggested to check it while debugging a USB
C port not working on a Chromebook. The issue got fixed after a device hard
refresh: shutdown, hold the refresh button, turn on.

I knew about `file:///var/log/` but didn't find `chrome://device-log` anywhere
in the docs. Useful! This note is to that I'll remember about it.
