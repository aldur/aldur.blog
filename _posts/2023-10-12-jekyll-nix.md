---
title: 'Jekyll + Nix'
---

When I [started writing again](2023-10-07-reboot.md), getting this blog to
rebuild with [Jekyll](https://jekyllrb.com) wasn't easy. Let's fix that with
[Nix](https://nixos.org).

### Building with Jekyll

Jekyll is powered by Ruby. When I tried building it on macOS, installing its
Ruby `gem` either required `sudo` or failed when using `--user-install`[^gem].
Installing `ruby` from `homebrew` solved this, but:

- Required to prefix all commands with their full path[^keg_only], e.g.
  `/opt/homebrew/opt/ruby/bin/bundle exec jekyll serve`; and
- the installation path for gems depended on the current `ruby` version, e.g.
  `/opt/homebrew/lib/ruby/gems/3.2.0/`. The next `ruby` version upgrade would
  require re-installing the gems.

I could go on, but... How do we do better?

### Enters Nix

Nix creates reproducible build/execute system. This solves the problems
described here -- allowing me to forget about this blog and start over in a few
years, this time easily! But also provides other goodies:

- **Security:** Fully reproducible builds strengthens the _supply chain_. It
  _pins_ not only dependencies and their versions along the chain, but also the
  hashes of their packages (that's what `flake.lock` is for).
- **Quality of life:** Nix runs everywhere, including Docker and/or the CI. This
  means we can write _checks_ once (e.g., linters) and run them both locally and
  remotely. Without turning to `yaml` to instruct the CI/CD provider or to third
  party helpers to ease the pain (which would instead increase the supply chain
  _surface_).

In theory, this makes Nix _great_. Where's the catch? Two things at least. 1.
You need to learn it -- and it has quite a learning curve. 2. The target build
system must _collaborate_.

### Nix + Bundler

Let's look at our build system. Jekyll is a Ruby app that relies on
[Bundler](https://bundler.io):

> Bundler provides a consistent environment for Ruby projects by tracking and
> installing the exact gems and versions that are needed.

Developers specify their dependencies in a `Gemfile`. Bundler resolves them and
"locks" _all_ their _versions_ in a `Gemfile.lock` file. This includes any
transitive dependency. But, alas for us, `Gemfile.lock` doesn't include package
hashes (for instance, Python's `Pipfile.lock` does this). This makes our build
only _half-reproducible_. What would happen if someone modifies the contents of
a Ruby gem that was previously published (and tagged)? We would have no way of
noticing on a fresh build!

Solving this requires us to bring in another tool (in addition to `nix`, and
`bundler`): [`bundix`](https://github.com/nix-community/bundix), which creates
_one more lock file_, `gemset.nix`, holding the packages hashes that Nix will
consume.

<div class="note" markdown="1">
{:.text-align-center}
![Gemfile → Gemfile.lock → gemset.nix](../images/gems.webp){:.centered}
_Getting dependencies, versions and hashes._
</div>

<div class="hint" markdown="1">
🛑 Let's stop for a second.

`bundix`, as all software here, is _open-source_. Volunteers (often only one)
dedicate their free time to build it and maintain it.

It is _mind-blowing_ to consider that these tools even exist. They solve problems
_well_, _once_, and _for all_. Think about the effort dedicated to making them
_so powerful_ and the impact that we (the people) have when we leverage them.

The issues in this post are _first-world problems_, that only deal with how I'd
like to fit these tools into my workflow.

If you are an opensource contributor: Thank you!
<br>
If you are not (yet), please
consider supporting your favorite projects by contributing or sponsoring them.

Back to work.

</div>

### Bundix: Hammering down issues

To get `bundix` to work correctly we need to hammer down a few things.

Some Ruby gems provide platform-specific packages. `bundix` gets [_confused_
about them](https://github.com/nix-community/bundix/issues/88) and fetches the
wrong package/hash[^bundix]. We can fix it by asking it to always compile from
source (see
[`force_ruby_platform`](https://bundler.io/v2.4/man/bundle-config.1.html) and
remember to regenerate your `Gemfile.lock`).

Also, we now need to keep `gemset.nix` up-to-date if we make changes to
`Gemfile.lock`.

<div class="warning" markdown="1">
Don't be tempted, as I was, to have Nix generate it automatically at build time.
That would break reproducibility (again)!
</div>

Instead, I tried to _ensure_ this condition by writing a Nix check (technically,
a `flake check`) that would re-generate `gemset.nix` and fail if different from
the original. Alas, this approach didn't work. Under the hood, `bundix` calls
`nix-instantiate`, and calling `bundix` within our check fails -- the
[sandbox](https://discourse.nixos.org/t/what-is-sandboxing-and-what-does-it-entail/15533)
prevents us from nesting builds[^sandbox].

So far, I haven't found an alternative way to do this. I could write a separate
CI check that _calls_ `bundix`, but that would defeat the point. You win this
one, `bundix`!

### The full nix flake

Writing the rest of the `flake.nix` file ({% include github_link.html
url="https://github.com/aldur/aldur.github.io/blob/ad72870b4ae0c89cf99f99e9b33270b71fc8844a/flake.nix"
text="full result here" %}) gives us our reproducible system.

We can now run `nix run` to download any required package/flake, build the blog,
and serve it. `nix run .lockGemset` will (you guessed it) generate `gemset.nix`.
`nix flake check`, instead, will ~~ensure that the `gemset.nix` file is in-sync
with `Gemfile.lock`~~ ensure the blog builds.

### 💰 -- _aka_, hidden costs

<div class="note" markdown="1">
Hey, did I just read about a bunch of _tradeoffs_? <br>
That's right!
</div>

To get to reproducible builds, we had to:

- Bring in additional abstractions (Nix, `bundix`).
- Drop pre-compiled libraries and compile everything from source.
- Introduce the redundancy of `gemset.nix`.

Every fix and abstraction adds more indirection, which brings it _complexity_.
That we need to know about, manage, evaluate.

<div class="note" markdown="1">
{:.text-align-center}
![OS, nix, bundix, bundler, jekyll, this blog](../images/stack.webp){:.centered}
_The reproducible (but more complex) stack now powering this blog._
</div>

Back to a [product mindset](2023-10-07-zap-it.md) how do we weigh benefits and
costs? Luckily, we don't!

I am not at work™, I am doing this for fun. Plus, I get to rant about it.

<div class="note" markdown="1">
🥷

Allow me to just point out these hidden costs and not worry about them but
just enjoy `nix run`. <br>
I'll show myself to the door. 'til next time! 👋

</div>

#### Footnotes

[^gem]: Truth to be told, I didn't try too hard to fix this.
[^bundix]:
    This `bundix` [fork](https://github.com/inscapist/bundix) deals with
    native dependencies and their packages. In my case, it failed while starting.
    The errors hinted to a library version mismatch (maybe due to [its Ruby
    3.1](https://github.com/inscapist/bundix/blob/5cb01869cb09fb367c02527b1f66707fb9277076/flake.nix#L21)
    vs Ruby 3.2 used for this blog). I decided that was as deep as I would go
    through the rabbit hole and went back to compiling gems from source.

[^keg_only]: `brew info ruby` reads:

    ```txt
    ruby is keg-only, which means it was not symlinked into /opt/homebrew,
    because macOS already provides this software and installing another version in
    parallel can cause all kinds of trouble.
    ```

[^sandbox]:
    This got me quite confused for a second. On macOS, the check I had {%
    include github_link.html
    url="https://github.com/aldur/aldur.github.io/pull/4/files/774d4792fa7265a99b7c19390cfec2c13293897a#diff-206b9ce276ab5971a2489d75eb1b12999d4bf3843b7988cbe8d687cfde61dea0R95" text="originally written" %} was working as expected, but it would fail on CI. That's
    because sandboxing is disabled on macOS, but enabled on CI.
