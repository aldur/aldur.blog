---
title: 'Shell pipes break readline completion'
date: 2025-02-01
last_modified_at: 2025-07-10
redirect_from: /articles/2025/02/01/pipes.html
---

Seemingly at random I found myself without `readline` in my terminal,
just for it to restart working later on. This seemed to happen especially when
trying to use `pdb` after setting a Python `breakpoint()`.

I originally thought about my `TERM` variables being misconfigured, the use of
`direnv`, and so on. But it was none of that. On a closer look, it only
happened when running `make extract` to process Beancount transactions from
bank statements and financial documents. Why?

The Makefile `extract` target looks as follows:

```txt
extract:
  $(RUN) bean-extract -f $(INDEX).beancount -e $(INDEX).beancount $(INDEX).import "$(EXPANDED_TARGET)" | tee /tmp/extracted.beancount
```

It calls `bean-extract` and then pipes the result to a file. When this would
fail (under the hood, it calls a bunch of Python script that parse the
different documents), I'd throw a `breakpoint()`, get into `pdb` and be annoyed
by the lack of completion.

Other times, I'd run the command directly -- and readline completion would work,
deepening the mystery.

It then dawned on me and in retrospect it is obvious; I should have noticed
earlier. Well-behaved Unix processes will detect that their standard input is
not a terminal and disable shell completion (often implemented through GNU
`readline`).

For CPython, I _think_ the relevant code is [here][0]. Entering text into a
terminal is [indeed complicated][2].

Mystery solved! Here the behavior in action:

{:.text-align-center}
![A terminal screencast showing how pipes break completion](../images/pipes.svg){:.centered}
Also on [asciinema][1]

[0]: https://github.com/python/cpython/blob/71ae93374defd192e5e88fe0912eff4f8e56f286/Parser/myreadline.c#L2
[1]: https://asciinema.org/a/FpGU25luEC4q30STLGw4Lj0fX
[2]: https://jvns.ca/blog/2024/07/08/readline/
