---
title: 'Fix Slack notifications in Safari'
date: 2026-01-16
---

Somehow, Slack in Safari never notified me within a particular
workspace/profile.

The Slack [troubleshooting guide][0] suggested to check that Safari's
preferences allowed notifications from the Slack website. But I never got the
prompt to allow that in the first place: `app.slack.com` was missing from the
settings, both in Safari and in macOS' notification center.

{:.text-align-center}
![A screenshot from the Slack troubleshooting guide for Safari](../images/safari-troubleshoot.webp){:.centered style="width: 70%; border-radius: 10px;"}
_Slack's troubleshooting guide for Safari._

To fix it, I manually requested the permission to show notifications from the
developer console of Slack's tab:

```javascript
Notification.requestPermission().then(permission => {
  if (permission === 'granted') {
    new Notification('Hello!', {
      body: 'This is a notification from Safari',
      icon: '/path/to/icon.png'
    });
  }
});
```

After that, notifications started to work.

[0]: https://slack.com/help/articles/360001559367-Troubleshoot-Slack-notifications#browser-2
