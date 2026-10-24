---
title: 'Importing p12 certificates on a Chromebook'
date: 2026-01-22
tags: [ChromeOS]
---

I sometimes need to use a Chromebook and a `.p12` certificate to authenticate
through TLS (e.g. through the Spanish "Identificación electrónica"). Everytime
that happens, I need to "rediscover" the process. Here it is for future memory.

To add a `.p12` certificate to ChromeOS' certificate manager:

1. Navigate to `chrome://certificate-manager`
1. → "_Your certificates_"
1. → "_View imported certificates from ChromeOS_"
1. → "_Import and bind_"
1. Select your certificate from the file picker
1. Enter your certificate's password

"_Import and bind_" stores the certificate [on the device's Trusted Platform
Module (TPM)][0].

It might be possible to also store the certificate on a YubiKey through the
[Personal Identity Verification (PIV)][2] app and then use it on a Chromebook
through the [Smart Card Connector][1] and a middleware. I haven't tried this
approach yet, but I hear it is tricky on non-enterprise devices.

[0]: https://www.chromium.org/developers/design-documents/tpm-usage/#protecting-certain-user-rsa-keys
[1]: https://chromewebstore.google.com/detail/smart-card-connector/khpfeaanjngmcnplbdlpegiifgpfgdco?sjid=12624726738251298427-NA
[2]: https://docs.yubico.com/yesdk/users-manual/application-piv/slots.html
