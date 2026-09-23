---
title: 'MLX with Metal support through Nix'
date: 2025-11-04 22:48
---

We have [talked about](unlimited-tokens-with-llm-mlx.md) how I like running
local models on macOS through the [MLX framework][0]: it is _fast_ and it
doesn't require an `ollama` daemon in the background. [`simonw/llm`][1]
provides good CLI ergonomics (for instance, to provide examples, set a system
prompt, temperature, etc.).

I also like my pipelines deterministic so that upstream releases don't break
them by mistake. For this, I use Nix to package things up.

Unfortunately, when using the `mlx` Nix derivation available in `nixpkgs`, the
CLI would stall and the inference process would eventually `SIGSEV`. That's
because that derivation [does not build with Metal support][2]:

```txt
# NOTE The `metal` command-line utility used to build the Metal kernels is not open-source.
# To build mlx with Metal support in Nix, you'd need to use one of the sandbox escape
# hatches which let you interact with a native install of Xcode, such as `composeXcodeWrapper`
# or by changing the upstream (e.g., https://github.com/zed-industries/zed/discussions/7016).
```

The sandbox escape hatch sounds scary. Instead, I fixed it by pulling wheels
from Pypi (it turns out that `mlx` and `mlx-metal` are required) and patching
them to work with Nix.

If anyone needs it, {% include github_link.html
url="https://github.com/aldur/dotfiles/blob/1b93ba9ace983a875034bb41718b22bca427cfdd/nix/packages/mlx/default.nix"
text="here is the resulting derivation" %}. Below it is in action:

```bash
echo "Hi" | nix shell .#llm -c llm prompt -m mlx-community/Llama-3.2-3B-Instruct-4bit

How can I assist you today?
```

[0]: https://github.com/ml-explore/mlx
[1]: https://github.com/simonw/llm
[2]: https://github.com/NixOS/nixpkgs/blob/b3d51a0365f6695e7dd5cdf3e180604530ed33b4/pkgs/development/python-modules/mlx/default.nix#L78C1-L81C102
