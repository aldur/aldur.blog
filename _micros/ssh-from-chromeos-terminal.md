---
title: 'SSH from ChromeOS'
date: 2025-07-28
tags: [ChromeOS]
---

ChromeOS allows SSH authentication through either the built-in Terminal
application or the [Secure Shell
extension](https://chromewebstore.google.com/detail/secure-shell/iodihamcpbpeioajjeobimgagajmlibd).
The way this works is pretty cool! An "HTML terminal", named
[`hterm`](https://chromium.googlesource.com/apps/libapps/+/HEAD/hterm)
provides the terminal emulator. An SSH client does the rest.

#### A tale of two clients

You might now be asking: Wait, how do you get an SSH client running in the
browser?

Here is where things get complicated:

- Back in the day, the SSH client was
  [`nassh`](https://chromium.googlesource.com/apps/libapps/+/HEAD/nassh), an
  SSH client built for Chrome's Native Client
  ([NaCl](https://developer.chrome.com/docs/native-client)).
- In 2020, NaCl has been deprecated in favor of WASM.
  [`wassh`](https://chromium.googlesource.com/apps/libapps/+/HEAD/wassh/),
  a WASM SSH client, replaced `nassh`.

Secure Shell and the Terminal will default to the newer `wassh`, unless forced
to pick `nassh` through the `--ssh-client-version=pnacl` relay server
[option](https://chromium.googlesource.com/apps/libapps/+/HEAD/nassh/docs/options.md).

#### Yubikey support

Now things get messy. I generate my
[SSH identities on a Yubikey](../_posts/2025-06-26-yubikey-agent.md). Terminal
and Secure Shell
[support](https://chromium.googlesource.com/apps/libapps/+/HEAD/nassh/docs/hardware-keys.md)
Yubikeys thanks to the [Smart Card
Connector](https://chromewebstore.google.com/detail/smart-card-connector/khpfeaanjngmcnplbdlpegiifgpfgdco)
app and the `--ssh-agent=gsc` relay option.

Unfortunately, `wassh` never worked for me on this configuration, failing with
the following error:

{:.text-align-center}
![A screenshot of the Terminal application failing to establish an SSH connection.](../images/failing-ssh-chromeos.webp){:.centered}
> _Program exited with status code [object Object]._

For a while, I could work around the issue by using the old SSH client through
`--ssh-client-version=pnacl`. New Chromebooks, however, do not ship NaCl
anymore. This makes Terminal hang on "Loading pnacl program..." when trying to
start the client. Unsurprisingly, this breaks the workaround.

#### Patching `wassh`

This left me with no other solution than to debug the `wassh` client. I started
by opening the developer console
((<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>J</kbd>)) in a failing Terminal and
diving into the 🐇 rabbit hole that starts with this:

```txt
terminating process due to runtime error: Error while handling syscall: TypeError: onSuccess is not a function
TypeError: onSuccess is not a function
    at SshAgentStream.asyncWrite (chrome-untrusted://terminal/js/nassh_stream_sshagent.js:105:3)
    at UnixSocket.write (chrome-untrusted://terminal/wassh/js/sockets.js:1523:26)
    at RemoteReceiverWasiPreview1.handle_fd_write (chrome-untrusted://terminal/wassh/js/syscall_handler.js:299:15)
    at Background.onMessage_syscall (chrome-untrusted://terminal/wasi-js-bindings/js/process.js:293:40)
    at Background.onMessage (chrome-untrusted://terminal/wasi-js-bindings/js/process.js:276:28)
```

Through some JavaScript abominations and Chrome local overrides, I managed to
work around one JavaScript issue after the other. Then, a [helpful
answer](https://groups.google.com/a/chromium.org/g/chromium-hterm/c/hO3-iwRQ0tI/m/7Eo8RtSIAQAJ)
on the `chromium-hterm` Google Group pointed me to a [stale pending
change](https://chromium-review.googlesource.com/c/apps/libapps/+/6232681) that
fixes the issue. I applied it to the overrides and verified that it works.

#### Profit?

Kinda. As long as the changes are pending, SSH from the Terminal requires to:

1. Configure the connection.
1. Launch the client.
1. See it fail.
1. Open the developer console, which loads the overrides.
1. Force-reloading the client with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd>.

If all the steps went correctly, this should result in the Yubikey PIN prompt.
It works, and it is great that it does since it provides a fallback in case
something else breaks and you need SSH from ChromeOS. But the UX _sucks_.

It _might_ be possible to make things less wonky by packaging a patched version
of the Secure Shell extension and using it, but I have not tried that. But that
might be just a temporary stopgap: ChromeOS will be deprecating Chrome Apps,
including the Smart Card Connector. Instead, I think that a better solution can
now just rely on
[Fido2](https://fidoalliance.org/fido2-2/fido2-web-authentication-webauthn/)
for SSH. That would allow re-using the browser support for WebAuthn and remove
the need for the connector altogether.
