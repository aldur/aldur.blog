---
title: 'Stop claude-code from fetching git at startup'
date: 2026-03-12
---

Since a couple of weeks ago, issuing a first prompt to `claude-code` results in
an unattended request to unlock/touch the YubiKey that holds my SSH keys, as if
it is trying to do a `git` operation on my behalf. The whole thing is
confusing, because the YubiKey request is "blind": it doesn't specify which
command is being executed and for which purpose. Others have noticed the
[issue][0] as well.

It looks like `claude-code` does a `git fetch` at startup, which requires SSH
if the repository was cloned that way. To fix it, set this environmental
variable:

```bash
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

From the [manual][1]:

> CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: Equivalent of setting
  DISABLE_AUTOUPDATER, DISABLE_BUG_COMMAND, DISABLE_ERROR_REPORTING, and
  DISABLE_TELEMETRY

I haven't tried scoping it down to one of these variables, let me know if you
do! Meanwhile, this should also prevent `claude-code` from asking for
feedback during a session.

[0]: https://github.com/anthropics/claude-code/issues/21108
[1]: https://code.claude.com/docs/en/settings
