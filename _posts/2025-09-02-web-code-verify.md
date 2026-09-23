---
title: "Code integrity for web apps"
excerpt: >
  Threat modelling around web and native applications.
---

I used to prefer web-apps to their native equivalents, especially if the
"native" one is just wrapping a browser anyway (e.g., through Electron). Here
is why:

- Web-apps run within the browser sandbox, adding to _defense in depth_. The
  browser is _designed_ to execute untrusted code and prevent it from "spilling
  over" to the rest of the system[^silver_bullet]. A malicious web page should
  _not_ be able to access your documents or read your emails.
- Native apps, instead, can access the underlying OS more directly[^sandbox].
  They can read and write the filesystem, execute arbitrary commands, connect
  to other machines, start whenever you log-in, etc.

[^silver_bullet]: Not a [silver-bullet][0], but still useful.
[^sandbox]: Most operating systems run native apps in a sandbox as well, but it is
         harder for users to tell when that is the case. For instance,
         on macOS apps will run in two different sandboxes depending on whether
         they are from the App Store or not.

A few days ago, a potential flip side of web-apps made me rethink things more
thoroughly. How do we know that we are running a "honest" web-app, instead of
one modified by an attacker?

### Web vs native apps

<picture class="text-align-center" markdown="1">
  <source srcset="{% link images/web-app-light.svg %}" media="(prefers-color-scheme: light)">
  <source srcset="{% link images/web-app-dark.svg %}" media="(prefers-color-scheme: dark)">
  <img src="{% link images/web-app-dark.svg %}" alt="A web-browser fetching a web-app and an encrypted payload from a server. The browser holds a cryptographic key, used to decrypt the encrypted payload." class="centered">
</picture>

The browser downloads web-apps every time we use them (unless cached). If an
attacker could _modify_ the web-app being downloaded, then they would control
_its context_. If it's a messaging app, they could read or send messages. If
it's a password manager, they could access passwords or secrets.

<picture class="text-align-center" markdown="1">
  <source srcset="{% link images/attacker-app-light.svg %}" media="(prefers-color-scheme: light)">
  <source srcset="{% link images/attacker-app-dark.svg %}" media="(prefers-color-scheme: dark)">
  <img src="{% link images/attacker-app-dark.svg %}" alt="A web-browser fetching a web-app, modified by an attacker, and an encrypted payload from a server. The browser holds a cryptographic key, used to decrypt the encrypted payload. The cryptographic key leaks to the attacker." class="centered">
</picture>

To pull this off, the attacker would have to compromise the web-servers
providing the code (including any content delivery networks) or succeed in a
man-in-the-middle attack. Realistically, these attacks are relatively hard to
pull off at scale, but are possible for sophisticated-enough attackers.

In comparison, native apps deploy counter-measures against all this. They are
typically bundled, signed, and then downloaded through a separate channel
(e.g., the App Store or a link to a DMG or deb package). This allows users (or
their OSs) to validate the bundle's integrity before executing the app,
assuming: 1. a public key infrastructure (PKI) to associate the application
signing keys to the application developer; 2. that the signing keys have not
been compromised; 3. that the user downloaded the right application in the
first place. The bar for an attacker to compromise this process _can_ be
higher, e.g., if the developers appropriately protect their signing keys in
cold storage.

### With E2EE

Code integrity is particularly important around end-to-end encryption (E2EE).
With E2EE messaging apps (Signal, WhatsApp, Matrix) and password managers
(1Password, Bitwarden), the server cannot decrypt user data, but simply holds
encrypted payloads. The client receives them, decrypts them, and displays the
result to the user. The integrity of the client is _fundamental_. A compromised
client can completely circumvent E2EE and leak messages, keys, and passwords.

#### Signal

The lack of code verification in the browser is [why Signal does not offer a
web client][4] and instead provides a native one based on Electron
(essentially, a web page served by a _signed_ native app). It all boils down to
verifiable distribution. This way, users download the Signal app only once,
right before they install it. They do not need to "blindly" trust it, but can
verify its integrity by checking that it was signed by the Signal developers[^signal].
With web-apps, instead, users download the code at every visit _and_ they
cannot easily verify what is being served to them.

[^signal]:
    On macOS, `Signal.app` is signed through Signal's Apple developer account.
    Debian packages instead rely on a GPG signing key. The operating system should
    typically perform the verification on behalf of the user.

#### Meta

Meta has also addressed this threat for their E2EE apps as well. To mitigate
it, they released the ["Code Verify"][5] extension, covering [WhatsApp][1],
Instagram, Facebook Messenger. Under the hood, the extension compares the
hashes of each file being executed against a "root hash", fetched both from a
manifest _and_ from [Cloudflare][2]. In essence, the extension replicates the
checks performed by the OS' "gatekeeper" when executing a native app. It is a
nice solution, but it is _not_ perfect. First, users need to know about the
extension and install it on all their browsers. I discovered its existence just
a few days ago. Then, they need to notice the extension's warning in case
something is off. Lastly, the extension adds another component that could be
bypassed or exploited. The code is relatively simple and open-source, so this
seems unlikely – but not impossible.

#### Evolving standards

A better fix would be to systemically solve this by improving things for
_everyone_ by providing better security, by default. For this to work, there
needs to be a coordinated effort so that browsers validate the code against a
"root of trust" before executing the application, similarly to how they ensure
the integrity of websites served through TLS.

While I was researching all this, someone on IRC nicely pointed me to [Isolated
Web Apps][6], which have been designed to solve this problem _but also_ allow a
wider set of capabilities for the browser (e.g., opening raw sockets). As it
happens with coordinated efforts, it takes some time to reach consensus on the
best approach:

1. Chrome is experimentally allowing Isolated Web Apps for [enterprise
   Chromebooks][7].
1. [WebKit][3] hasn't taken a position yet.
1. Mozilla has instead [declined to adopt them][8], stating that the
   additional capabilities introduce new hazards and that a new,
   [in-development standard][9], would be a better solution.

Despite the time it will take, I consider this great news! Bright people
are working so that we will _all_ be able to validate the integrity of
web-apps. Eventually, one or more standards will emerge, be implemented, and
advance everyone's security.

### For users

What does all this mean for me and you, the users? It depends on the threat
model.

1. **E2EE service**: If you are protecting against _"someone trying to break
   E2EE for a specific service"_, then native apps offer an additional line of
   defense, preventing a modified client from running. The assumption is that
   we trust the application developer, because we use their E2EE service _and_
   we run their app.
1. **Local device compromise**: If instead you are protecting against _"someone
   trying to compromise my endpoint"_, then web-apps offer additional
   protection because of the browser sandbox. Same goes for _"I do not trust
   the application developer and I want to limit their access to my system"_.

Now, threat model (2) is _a lot more general_ than (1). If someone manages to
compromise my device, chances are that they will _also_ be able to break E2EE
for any app I use there[^1p]. If, instead, someone serves me a malicious WhatsApp
web-app, they will be able to read messages or send new ones, but will most
likely not be able to also read my emails or steal my passwords.

[^1p]: As [1Password puts it][10]:

     > There’s no password manager or other mainstream tool with the ability to
     guard your secrets on a fully compromised device.

Password managers are a notable exception, because an attacker can leverage
them to try accessing other services and increase the blast radius. But I argue
that even then, MFA should prevent most damage – as long as the _other_ factors
are _not_ in the password manager, the attacker won't be able to log in. In
addition, most services today notify users about new or unusual logins,
alerting them that something might be going on. Compare this with when a device
is compromised: an attacker who steals a session token might be able to use it
without triggering a new login notification.

Due to all this, I consider web-apps a better fit for a majority of users
(myself included), especially when used through a thin client (e.g., a
[Chromebook](2025-06-19-nixos-in-crostini.md)). Encouraging users _not_ to
download and install native software makes device compromise less likely and
_localizes_ the blast radius (e.g., to the specific compromised app). Isolated
Web Apps (or similar) will be a welcome addition once they standardize, adding
one more layer of protection to the web. Meanwhile, the Code Verify extension
probably doesn't hurt the services it covers.

Threat modeling is not one-size-fits-all, though, and each user should think
carefully about what they are protecting from. For instance, if you are a
whistle-blower, a leak of your Signal messages could lead to fatal
consequences, more severe than someone being able to access your financial data
or log-in as you on Facebook. This is why I appreciate the thoughtfulness of
Signal developers, providing a client that is secure against those most-severe
threat models and prevents _those_ users from making a wrong choice.

As for me, I hope that this deep dive will help you (as it helped me) to define
your threat model more explicitly and weight the associated trade-offs. If you
have thoughts about all this, I would love to hear them and chat about it.
Please, reach out! Meanwhile, thank you for reading and see you next time! 👋

#### Footnotes

[0]: https://nvd.nist.gov/vuln/detail/CVE-2025-6558
[1]: https://faq.whatsapp.com/1210420136490135/?cms_platform=web
[2]: https://blog.cloudflare.com/cloudflare-verifies-code-whatsapp-web-serves-users/
[3]: https://github.com/WebKit/standards-positions/issues/184
[4]: https://www.reddit.com/r/privacy/comments/uwpoyb/comment/i9tj457/
[5]: https://github.com/facebookincubator/meta-code-verify
[6]: https://github.com/WICG/isolated-web-apps
[7]: https://chromeos.dev/en/web/isolated-web-apps
[8]: https://github.com/mozilla/standards-positions/issues/799
[9]: https://github.com/mozilla/standards-positions/issues/799#issuecomment-2861412906
[10]: https://blog.1password.com/local-threats-device-protections/
