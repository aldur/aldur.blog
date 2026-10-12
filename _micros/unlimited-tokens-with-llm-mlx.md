---
title: 'Unlimited tokens with llm-mlx'
date: 2025-07-13
related:
  - _micros/mlx-with-metal-support-through-nix.md
  - _posts/2026-10-05-offline-local-inference-on-macos.md
---

I like playing with self-hosted LLMs on Apple hardware through [`llm-mlx`][0],
because it doesn't require running any additional service (e.g., `ollama`) and
produces tokens faster.

When asking the model for longer outputs (e.g., when requesting a structured
JSON conforming to a given schema), the model would sometimes stop in the
middle of a sentence (or a data structure), and I could not figure out why. 
Using the same model through `ollama` did not have the same problem.

For instance, the output of this prompt, shown below, is clearly truncated:

```bash
echo "Write 1000 words about the answer to universe, life and everything" | llm prompt -m mlx-community/gemma-3-12b-it-qat-4bit
```

Results in this output, clearly truncated mid-sentence:

<details markdown=1>
  <summary markdown=span>Click to see full output</summary>
> ### 42: Beyond the Number, Exploring the Answer to Everything
> 
> Douglas Adams’ *The Hitchhiker’s Guide to the Galaxy* famously posits that the answer to the ultimate questions of life, the universe, and everything is 42. It's a brilliant, absurd, and ultimately profound joke, but the joke itself begs a deeper exploration. While the number itself holds little inherent meaning within the narrative, the quest to *find* it, and the subsequent disappointment when it's revealed as a seemingly random digit, speaks volumes about humanity's persistent search for meaning in a vast and often baffling cosmos.  Let's unpack the joke, the number's cultural impact, and, most importantly, what the pursuit of "the answer" might actually reveal about our understanding of the universe, life, and everything.
> 
> **The Absurdity of a Definitive Answer**
> 
> The brilliance of Adams' joke lies in its dismantling of the very notion of a singular, definitive answer.  Humans, throughout history, have sought grand unifying theories – philosophical systems, religious doctrines, scientific models – that promise to explain everything.  We crave order, predictability, and a sense of control in a universe that often feels chaotic and indifferent to our existence.  The supercomputer Deep Thought, tasked with calculating the Answer to the Ultimate Question, spends seven and a half million years crunching numbers, only to deliver a number devoid of context.
> 
> This is precisely Adams' point. The question itself might be flawed. The universe might not operate on principles easily digestible by human intellect. The quest for a single, all-encompassing answer may be a futile exercise, born from our innate desire to simplify and categorize.  We often impose order on a reality that may be fundamentally beyond our ability to fully comprehend.  Imagine trying to explain quantum mechanics to a goldfish – the concepts are simply beyond its cognitive framework. Perhaps we are, in a cosmic sense, that goldfish, struggling to grasp the vastness and complexity of existence.
> 
> **The Number 42: More Than Just a Joke**
> 
> While Adams claimed he chose 42 randomly, the number itself has taken on a life of its own. Mathematicians and number enthusiasts have pointed out various interesting properties:
> 
> * **Binary Representation:** In binary, 42 is represented as 101010, which some find aesthetically pleasing and potentially symbolic.
> * **Sum of Triangular Numbers:** 42 is the sum of the first six triangular numbers.
> * **ASCII Code:** The ASCII code for the asterisk (*) character, often used as a wildcard in computer programming, is 42. This connection to computers resonates with the narrative's focus on technology and artificial intelligence.
> * **Mathematical Significance:**  While not profoundly significant in itself, 42 is a common number in various mathematical contexts, subtly reinforcing the idea that even seemingly random numbers can hold a certain resonance.
> 
> However, attributing profound meaning to these coincidences misses the core of Adams’ message. The fact that people *seek* to find meaning in the number 42 is far more significant than the number itself. It demonstrates our innate tendency to search for patterns and connections, even in the face of randomness.
> 
> **Beyond the Answer: The Value of the Question**
> 
> If 42 is not the answer, then what is? Perhaps the pursuit of the answer is more valuable than the answer itself.  The story of Deep Thought highlights this perfectly. The computer calculates the answer, but doesn’t know the question. It then needs to build an even larger computer, Earth, to determine what the Ultimate Question actually *is*.
> 
> This reveals a crucial truth: understanding the universe isn't about arriving at a final, definitive answer. It's about the ongoing process of asking better questions.  Scientific progress isn’s about achieving absolute certainty; it's about refining our understanding through observation, experimentation, and critical thinking. Philosophical inquiry isn’t about reaching a conclusive state; it’s about exploring different perspectives, challenging assumptions, and continually revising our worldview.
> 
> **The Universe, Life, and Everything: A Multifaceted Perspective**
> 
> Let’s break down the three components of the ultimate question and consider what a more nuanced approach might yield:
> 
> * **The Universe:** Modern cosmology paints a breathtakingly vast and complex picture. We’re grappling with dark matter, dark energy, the possibility of multiple universes, and the fundamental laws that govern reality. There's no single, easy-to-understand answer to "What is the universe?" Instead, we have a constantly evolving model based on observation and theory, acknowledging the limits of our current knowledge. The universe isn't a static entity waiting to be understood; it's a dynamic, expanding, and potentially infinite system.
> * **Life:** The origin of life remains one of the greatest mysteries. While we've made significant strides in understanding the building blocks of life and the conditions that might have fostered its emergence
> 
</details>

After some digging through the [source
code](https://github.com/simonw/llm-mlx/blob/b477833b807143241220f6561742833070d907cc/llm_mlx.py#L20),
I found out that the plugin by default will cap output at 1024 tokens. 

We can confirm that is the case by running the tokenizer on the output:

```python
#!/usr/bin/env python3

import sys
from mlx_lm import load

_, tokenizer = load("mlx-community/gemma-3-12b-it-qat-4bit")
print(len(tokenizer._tokenizer(sys.stdin.read()).input_ids))
```

```bash
pbpaste | uvx --with mlx_lm python3 /tmp/count_tokens.py
Fetching 13 files: 100%|█████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 13/13 [00:00<00:00, 260889.72it/s]
1023
```

Adding `-o unlimited true` fixes the issue for a single invocation of the CLI.
We can also make it permanent as follows:

```bash
$ llm models options set mlx-community/gemma-3-12b-it-qat-4bit unlimited true
Set default option unlimited=true for model mlx-community/gemma-3-12b-it-qat-4bit
```

[0]: https://github.com/simonw/llm-mlx/tree/main
