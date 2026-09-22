---
title: 'A VM guest for AutoFirma'
date: 2026-09-22
---

[AutoFirma][0] is a [Java desktop application][1] built by the Spanish
government to let citizens sign documents and identify themselves on
government websites.

Users load their digital certificates either directly into AutoFirma or into
their OS/browser keystore, so that they can use them to sign or authenticate.
When a website requires AutoFirma, it usually launches it through a deep link
and then communicates with it through WSS (WebSocket plus TLS).

For the WebSocket to work, the browser needs to trust its TLS certificate. But
AutoFirma communicates over `localhost`, which means it cannot ship a
trusted leaf certificate. Instead, it messes with the local keychain (at least
on macOS) to add a local certificate authority and a leaf certificate.

I don't particularly like any of this. I don't want it to add its own CA to my
system trust store. Plus, macOS support is [wonky][2].

Nowadays most government websites rely on TLS authentication, with the browser
supplying the certificate. Others, however, require users to use AutoFirma to
sign in or authorize operations. For those websites, there seems to be no way
around AutoFirma.

To contain all this, I asked an AI to bundle a browser and AutoFirma into a
Nix VM guest. The VM launches Firefox in a GUI and asks me to import a
certificate into a `tmpfs` store. When websites require it, AutoFirma
automatically opens and handles the signing.

The VM runs only essential services to keep the attack surface small. It builds
in CI, so I can just download it and run it with QEMU or Baguette. The
result is in [this GitHub repository][3]. It has made my life a bit easier.

[0]: https://firmaelectronica.gob.es/descargas
[1]: https://github.com/ctt-gob-es/clienteafirma
[2]: https://github.com/ctt-gob-es/clienteafirma/issues?q=is%3Aissue%20state%3Aopen%20macos
[3]: https://github.com/aldur/autofirma-vm
