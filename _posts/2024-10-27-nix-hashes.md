---
title: "Nix hash mishaps"
excerpt: >
  Lesson learned: double-check your Nix hashes for fixed-output derivations.
---

### The problem

A few days ago, I was preparing a Nix derivation including my Neovim
configuration and all its required plugins and executables (stay tuned for a
post about it!).

As I wrapped things into Nix derivations and tested the changes, I noticed that
my custom Neovim Markdown plugin was not loading correctly. In _theory_, it
should have been:

1. Packaged as a Nix derivation; and
1. Added to `neovim`'s `runtimepath`, to be loaded at startup.

I used `:scriptnames` to inspect which plugins were being loaded and from where.
Sure enough, I could see it loaded from a Nix store folder named
`/nix/store/ymfvbnw16qcy9y7m1mw92vd01ajl0kkb-vimplugin-vim-markdown/` (that is,
the result of a Nix derivation being built).

To my surprise, though, the directory did not contain the source code of my
plugin, but of _another_ plugin -- one that had nothing to do with it:

```bash
$ cd cd /nix/store/ymfvbnw16qcy9y7m1mw92vd01ajl0kkb-vimplugin-vim-markdown/
$ head -n 3 README.md
# gen.nvim

Generate text using LLMs with customizable prompts
```

Now, how did that happen? Here is a hint:

```nix
# ... your usual `flake.nix` boilerplate, we are in the `output` section.
packages.vim-markdown = (pkgs.vimUtils.buildVimPlugin rec {
  name = "vim-markdown";
  src = pkgs.fetchFromGitHub {
    owner = "aldur";
    repo = name;
    rev = "9fa61d2f5a1d28bc877e328b13ebdc3cac0d0f0e";
    hash = "sha256-jYUJO5vdoWHrxeZN30H5+zvWTePgmEnHig52fnVXrg8=";
  };
});
packages.gen-nvim =
  (pkgs.vimUtils.buildVimPlugin rec {
    name = "gen.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "aldur";
      repo = name;
      rev = "7ebb4f1";
      hash = "sha256-jYUJO5vdoWHrxeZN30H5+zvWTePgmEnHig52fnVXrg8=";
    };
  });
# ...
```

### The cause

Can you see it? Both derivations have the same `hash` -- the result of a
distracted copy/paste from my side.

```nix
# ... your usual `flake.nix` boilerplate, we are in the `output` section.
packages.vim-markdown = (pkgs.vimUtils.buildVimPlugin rec {
  name = "vim-markdown";
  src = pkgs.fetchFromGitHub {
    owner = "aldur";
    repo = name;
    rev = "9fa61d2f5a1d28bc877e328b13ebdc3cac0d0f0e";
    # 👇 here
    hash = "sha256-jYUJO5vdoWHrxeZN30H5+zvWTePgmEnHig52fnVXrg8=";
  };
});
packages.gen-nvim =
  (pkgs.vimUtils.buildVimPlugin rec {
    name = "gen.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "aldur";
      repo = name;
      rev = "7ebb4f1";
      # 👇 and here
      hash = "sha256-jYUJO5vdoWHrxeZN30H5+zvWTePgmEnHig52fnVXrg8=";
    };
  });
# ...
```

Why was this bad? The [`hash` attribute][hash] informs Nix that that particular
plugin is a _fixed-output derivation_ -- for which we already know the
cryptographic hash in advance. Most Nix _fetchers_ (that is, Nix expressions
that download things from the web) produce fixed-output derivations, relying on
the hash to ensure that the content downloaded had not been modified and is,
instead, as expected.

While building a fixed-output derivation, Nix will first check if there are
objects in its store that already match the output hash. In that case, it will
re-use them, instead of building the derivation (that is, fetching the sources).

That's what was happening. Nix was reusing the `gen-nvim`'s sources for
`vim-markdown`.

### The manual

The _Fetchers_ section of the `Nixpkgs` manual warns the user about it under
_[Caveats][caveats]_. Lesson learned!

> Because Nixpkgs fetchers are fixed-output derivations, an [output hash](https://nixos.org/manual/nix/stable/language/advanced-attributes#adv-attr-outputHash) has to be specified, usually indirectly through a `hash` attribute.
> This hash refers to the derivation output, which can be different from the remote source itself!
>
> This has the following implications that you should be aware of:
>
> - Use Nix (or Nix-aware) tooling to produce the output hash.
> - When changing any fetcher parameters, always update the output hash.
>   Use one of the methods from [the section called "Updating source hashes"](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-fetchers-updating-source-hashes).
>   Otherwise, existing store objects that match the output hash will be re-used rather than fetching new content.


### The solution

To fix this, all I had to do was set `vim-markdown`'s `hash` to
an empty string, have Nix complain about it when building the derivation, and
then use that:

```bash
nix build .#vim-markdown
warning: found empty hash, assuming 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
error: hash mismatch in fixed-output derivation '/nix/store/wfx7n8p2zdcmlbqn9fd8875p3gm4jajk-source.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-8pbPvTsFuJoWTeHGEa9Lm+aIkgeSVd56+hV95G1lg/0=
error: 1 dependencies of derivation '/nix/store/xqkdcayhjc56z3kqapbzszglk4k7nq3d-vimplugin-vim-markdown.drv' failed to build
```

Thanks for reading, and 'til next Nix surprise!

[caveats]: https://github.com/NixOS/nixpkgs/blob/4a817d2083d6cd7068dc55511fbf90f84653b301/doc/build-helpers/fetchers.chapter.md?plain=1#L31
[hash]: https://nix.dev/manual/nix/2.24/language/advanced-attributes#adv-attr-outputHash
