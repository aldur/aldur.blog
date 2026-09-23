---
layout: post
title: "My neovim setup for Beancount accounting"
categories: [articles]
date: 2024-03-01 18:00 +0100
---
I recently started using
[Beancount](https://beancount.github.io/docs/index.html) to implement [plain
text accounting](https://plaintextaccounting.org). This post describes my
approach around it and my `nvim` setup.

![A scene of double-entry bookkeeping reimagined in a vibrant cyberpunk setting -- DALL·E](../images/cyberpunk_ledger.webp){:.centered}

<div class="hint" markdown="1">
📒 Understanding why Beancount might be useful requires making sense of
[double-entry bookkeping](https://en.wikipedia.org/wiki/Double-entry_bookkeeping).

Rather than writing a half-baked explanation about it, I encourage you to skim
through Beancount's [getting
started](https://beancount.github.io/docs/getting_started_with_beancount.html)
guide if this sounds unfamiliar to you.

Go on, I'll wait here. ✌️
</div>

## My approach to Beancount

Beancount can shine only after we [bear the
pain](https://en.wikipedia.org/wiki/Activation_energy) of populating it with
recent transactions and then figure out a way to periodically keep track of new
ones. The easiest way I found to do this is by writing a few automated importers
for bank statements, exports from operations, and so on. Each importer will
parse a file (e.g., a CSV from your bank, or -- _sigh_ -- a PDF) and output one
or more Beancount transactions.

I have spread the effort of writing the importers and processing their output
over a few months, starting with more important accounts first and then slowly
adding other things. Depending on how you decide to structure transactions
(e.g., dividing expenses by type, payee, etc.), adding new entries will require
some manual post-processing to assign things to the right accounts. [This
tool](https://github.com/beancount/smart_importer/tree/main) can make things
easier after some initial manual work: it trains an SVC classifier that tries to
predict the right accounts for each transaction.

After a few iterations I ended up with a small Python library[^poetry_nix] that
can scan a directory for new files, extract their statements, and then archive
them. By filing them in the appropriate directory[^structure], Beancount will
automatically match documents to the accounts they relate to (e.g., an invoice
to its expenses account).

Overall, the process works well-enough, modulo that parsing some PDF statements
to extract balances is more art than science and will inevitably require some
evolution as the document structure will change.

I keep the full ledger within a single file[^manageable], divided in sections
(e.g., one per institution, year, etc.) through `nvim` folds (more
[below](#setting-up-nvim)). Being all text (plus the occasional PDF statement),
I use `git` to keep track of changes (both for the library and the journal).
Backups go through the same methods I use for the rest of the system (e.g., Time
Machine on macOS).

## Setting up `nvim`

The community has built [awesome tools](https://awesome-beancount.com) to manage
Beancount files. My weapon of choice for editing plain text files is
[nvim](https://neovim.io), and after experimenting with a few things I settled
on:

- A Tree-sitter [parser](https://github.com/polarmutex/tree-sitter-beancount)
  for indent and highlight.
- The built-in `bean-format` to consistently format the journal. I integrate it
  with `nvim` through the
  [efm-langserver](https://github.com/mattn/efm-langserver).
- An `nvim-cmp` [source](https://github.com/crispgm/cmp-beancount) to
  auto-complete accounts. The source enumerate accounts at startup and caches
  the result. As a result, it refused to auto-complete _new_ accounts created
  after opening the file. I {% include github_link.html
  url="https://github.com/aldur/dotfiles/blob/44b93c65671a84ea0ad595d8daab927299816c70/vim/lua/plugins/beancount.lua"
  text="hacked together" %} a `lua` function to manually refresh the cache when
  needed.
- A {% include github_link.html
  url="https://github.com/aldur/dotfiles/blob/44b93c65671a84ea0ad595d8daab927299816c70/vim/after_compiler/poetry-beancount.vim"
  text="custom `compiler`" %} that runs `bean-check` through `poetry`, based on
  [this plugin's](https://github.com/nathangrigg/vim-beancount) compiler. I
  quickly run it with `m<cr>`.
- A few {% include github_link.html
  url="https://github.com/aldur/dotfiles/blob/5e66b90598079c88b7de6a0256b60fda09580506/vim/after_ftplugin/beancount.vim"
  text="file-type options" %} to tell `nvim` how to deal with comments,
  formatting, and correctly split keywords:

  ```vim
  setlocal formatprg=bean-format

  setlocal comments=b:;
  setlocal commentstring=;%s

  setlocal iskeyword+=:
  ```
- `vim`'s default fold marker {% raw %}`{{{`{% endraw %} to split the file in
  sections. I write folds in comments, number them (so there's no need to close
  them) and nest them, e.g. {% raw %}`; --- Bank A {{{2`{% endraw %}.
- Last, I extended[^regex] [universal-ctags](https://github.com/universal-ctags/ctags)
  to support Beancount. This lets me easily jump to the opening directive of an
  account or to the definition of a commodity using
  `C-]` in `nvim`. The resulting `beancount.ctags` is {% include
  github_link.html
  url="https://github.com/aldur/dotfiles/blob/5e66b90598079c88b7de6a0256b60fda09580506/various/ctags/beancount.ctags"
  text="here" %}.

## Results

I am pretty happy with the overall setup.

After completing the costly first-time import, Beancount is useful to keep track
of financial assets, expenses, and book-keep in general. At first my
understanding about it was pretty limited: I used it to track monthly expense
against their budgets, or forecast them for incoming periods.

But Beancount can do a lot more! For instance, it generates comprehensive
financial reports and supports an SQL-like query language that will be pretty
useful for the next tax-reporting period -- replacing a bunch of hacky iPython
notebooks I had built over the years.

Reading [Financial Intelligence for
Entrepreneurs](https://financialintelligencebook.com/the-books/for-entrepreneurs/)
then gave it the finishing touch. The authors do a great job at helping those, like
me, unfamiliar with accounting making sense of balance sheets and income
statements. With a little practice I found it easy to apply their teaching to my
statements and found lot of value in the balance sheet and the income statement
that Beancount (or [fava](https://beancount.github.io/fava/), its web interface)
automatically generates.

And you, how do you use Beancount? If you have any feedback or comment, please
get in touch, I'd love to hear them.

Thank you for reading! 'til next time! 👋

#### Footnotes

[^poetry_nix]:
    `poetry` makes is easy to manage dependencies while
    [`poetry2nix`](https://github.com/nix-community/poetry2nix) ensures a
    reproducible environment through `nix`.

[^manageable]:
    As long as things remain manageable this way. I suspect that at some point
    the file length will make it complicated for `nvim` to handle things
    efficiently.

[^structure]:
    In my case, it looks as follows: `docs/<year>/<account>`, where `<account>`
    builds a directory tree from Beancount's account, turning `Assets:Checking`
    to `Assets/Checking`.

[^regex]:
    Adding a Beancount `ctags` parser was easier than expected, but took me
    longer than it should have because the manual states:

    > The regular expression, \<line_pattern\>, defines an extended regular
    > expression (roughly that used by egrep(1)), ...

    I tried for a while to use `\d` (supported by `egrep` but
    [not working](https://man7.org/linux/man-pages/man7/regex.7.html)
    in `ctags`) then went for `[0-9]`.
