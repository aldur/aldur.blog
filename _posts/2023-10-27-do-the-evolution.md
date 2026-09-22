---
layout: post
title: >
  Simulating individual selection with evolutionary game theory
categories: [articles]
excerpt: >
  Building a Python simulation for selecting and evolving "hawks" vs "doves"
  with evolutionary game theory.
---

<div class="note" markdown="1">
"Universal Bits", uh? I named this blog thinking about
articles like _this one_, applying computer science _bits_ to other fields.
</div>

<!-- prettier-ignore-start -->
#### Post outline
{:.no_toc}

- Table of Contents
{:toc}
<!-- prettier-ignore-end -->

## Introduction

Themes beyond my [circle of competence](https://fs.blog/circle-of-competence/)
attract my curiosity and fascinate the "explorer" within me. Better, they help
me create more effective _mental models_ of the world.

With this in mind, last spring, I finished reading [The Selfish
Gene](https://en.wikipedia.org/wiki/The_Selfish_Gene), by Richard
Dawkins[^40th].

Let's be frank. I studied computer science. Even after reading a couple books
about biology, I know very little about it.

But perhaps biology is not that different from computer science. Pick gene
sequence, encoding _expressions_ that mold ourselves and our _environment_. Now
compare them to computer code snippets, encoding _instructions_ for machines, to
teach them what to do. _Viruses_ are both biological and computational, invading
environments, altering individual behaviour, and replicating. Vaccines and
software patches mitigate them. And gene editing feels like reverse engineering!
But that is a story for another post.

If they're not _that_ far, then maybe we can apply the familiar lens of computer
science to learn biology. Through programs and simulations, replicating
what nature does best.

This post focuses on one field in particular, bridging biology, computer
science, and even economics: _game theory_. It explains equally well how peers
contribute to a decentralized system (for instance, in Web3) and how investors
behave in a market. Today, we look at it from an evolutionary perspective.

## Hawks and Doves

Chapter 5 of the Selfish Gene introduces _evolutionary game theory_ to
demonstrate how different individuals in a population adopt various
_strategies_, resulting in different _payoffs_, that affect their chances of
survival and reproduction.

Let's break this down.

Imagine observing a full ecosystem, isolated under a glass bell, where there
only live two species: _hawks_ and _doves_[^neil_young]. When looking at a pair
of individuals, you can't tell their species unless they engage in a _fight_.

Hawks fight _aggressively_ and only retreat after a serious injury. Doves
instead threaten the opponent, but cause no harm[^doves]. When a hawk encounters
a dove, the dove flees and no one gets hurt. When a hawk meets a hawk, they'll
fight fiercely until one of them will be injured (or dead). In the case of two
doves, they threaten each other until one _tires_ and backs down. In summary:

| _vs_     | Hawk                                          | Dove                               |
| -------- | --------------------------------------------- | ---------------------------------- |
| **Hawk** | Fight fiercely until one is seriously injured | The dove flees when attacked       |
| **Dove** | See _Hawk vs Dove_ (top right quadrant)       | Both threaten until one backs down |

These hypothetical fights represent fierce _competition_ for limited resources.
The winner _gains_ access to the resource and thereby develops a better position
to spread its genes. A species' _strategy_ defines their behaviour in fights --
in other words, how they interact with the surrounding environment and react to
external stimuli.

Assigning numerical scores to the result of fights allows us to compute
_payoffs_:

- +50 points for a win
- 0 points for a loss
- -100 points for serious injury
- -10 points for time lost

For instance, a hawk defeating a dove earns 50 points for winning, while the
dove gains 0 (for losing). In a hawk vs hawk fight, one gets injured and backs
down. That's -100 points, +0 for losing. The other gains 50 for winning. The
_expected payoff_ for such fight is -25 ((-100 + 50) / 2). When two doves
fight, one will eventually back down. The winner will earn +50, but they'll both
get -10 for losing time. Their expected payoff is 15 ((-10 + 50 - 10) / 2).

We can summarize all this through a payoff matrix:

<div markdown=1 id="payoff_matrix">

<style>
table {
    width: auto;
    margin-left: auto;
    margin-right: auto;
    display: table;
}
</style>

| Expected Payoff | Hawk | Dove |
| --------------- | ---- | ---- |
| **Hawk**        | -25  | 50   |
| **Dove**        | 0    | 15   |

</div>

The top right cell indicates that when a hawk fights a dove, the hawk's expected
payoff is 50, while the bottom right cell shows that when two doves face off,
their expected payoff is 15.

### Expected payoffs

Now, how does this connect to computer science? Through code. We will use Python
to represent the strategies and then probabilistically compute their expected
payoff.

To start, we enumerate strategies and points. Then we create a `dataclass` to
hold the results of simulated fights.

```python
import dataclasses
import random

from enum import Enum, IntEnum, auto

class Strategy(Enum):
    HAWK = auto()
    DOVE = auto()

    # make prettier prints
    def __repr__(self) -> str:
        return self._name_


class Points(IntEnum):
    WIN = 50
    LOSS = 0
    SERIOUS_INJURY = -100
    WASTE_OF_TIME = -10

    # make prettier prints
    def __repr__(self) -> str:
        return f"{self.value}"


@dataclasses.dataclass
class FightResult:
    a_payoff: int
    b_payoff: int

    def reverse(self):
        self.a_payoff, self.b_payoff = self.b_payoff, self.a_payoff
        return self

    def shuffle(self):
        if random.random() < 0.5:
            self.reverse()
        return self
```

`FightResult.shuffle` allows us to randomly select the winner and loser (through
a fair coin toss) when two individuals of the same species fight, like dove vs.
dove.

We can now add a `fight` function takes two strategies and returns the result.
It uses a touch of recursion to break the symmetry in outcomes (dove vs hawk has
the `FightResult.reverse` result of hawk vs dove).

```python
def fight(a: Strategy, b: Strategy) -> FightResult:
    match (a, b):
        case (Strategy.DOVE, Strategy.DOVE):
            return FightResult(
                Points.WIN + Points.WASTE_OF_TIME, Points.WASTE_OF_TIME
            ).shuffle()
        case (Strategy.DOVE, Strategy.HAWK):
            return FightResult(Points.LOSS, Points.WIN)
        case (Strategy.HAWK, Strategy.DOVE):
            return fight(b, a).reverse()
        case (Strategy.HAWK, Strategy.HAWK):
            return FightResult(Points.SERIOUS_INJURY, Points.WIN).shuffle()
        case _:
            assert False
```

Lastly, we conclude with a `simulate` function to:

- Sample two individuals from the population (without replacement), simulate a
  fight, and record the result.
- Produce the _expected payoff matrix_ by repeating the sampling and fighting
  process one thousand times.

```python
from itertools import groupby

def mean(x):
    ... # [...], does what you'd expect


def simulate(population, n_fights=1000) -> dict[Strategy, dict[Strategy, float]]:

    payoffs_by_species = collections.defaultdict(list)
    for _ in range(n_fights):
        a, b = random.sample(population, k=2)  # without replacement

        result = fight(a, b)

        payoffs_by_species[a].append((b, result.a_payoff))
        payoffs_by_species[b].append((a, result.b_payoff))

    def key(t):
        species, _ = t
        return species.value

    payoffs_matrix = {}
    for species, payoffs in payoffs_by_species.items():
        sorted_against_species = sorted(payoffs, key=key)
        grouped = groupby(
            sorted_against_species, key=key
        )  # needs elements sorted by group key
        payoffs_matrix[species] = {
            Strategy(s): mean(payoff for (_, payoff) in g) for s, g in grouped
        }  # the matrix row for `species`

    return payoffs_matrix
```

Let's test it.

```python
import pandas as pd

population_size = 100
population = [Strategy.DOVE] * (population_size // 2) + [Strategy.HAWK] * (
    population_size // 2
)
assert len(population) == population_size

split = collections.Counter(population)
print(split)
# >>> Counter({DOVE: 50, HAWK: 50})

payoffs_matrix = simulate(population)
payoffs_matrix = pd.DataFrame.from_dict(payoffs_matrix, orient="index")
print(payoffs_matrix)
# >>>                Strategy.HAWK  Strategy.DOVE
# >>> Strategy.DOVE            0.0           15.0
# >>> Strategy.HAWK          -25.0           50.0
```

<div class="hint" markdown="1">

If you prefer to look at the code, you can find the full source
{% include github_link.html url="https://github.com/aldur/hawks_and_doves" text="here" %}.

</div>

Sweet! We could have arrived to the same results through a mathematical approach
(in fact, we did that above 👆), but we are here to _simulate_ things. Plus, we
are about to make this more interesting by adding simulations for _evolution_
and _individual selection_.

### Towards evolution: Weighted Average Payoff

Let's state our assumptions:

- The payoff of fights represents access to (scarce) resources.
- More abundant resources improve the chances for an individual to reproduce.
  More resources correspond to a higher number of _offspring_.
- The organisms within our glass bell reproduce asexually and no mutations
  occur.

We can now introduce the concept of an individual's
[_fitness_](<https://en.wikipedia.org/wiki/Fitness_(biology)>) to represent their
"reproductive success" or, in other words, their chances of passing their genes
to a new generation.

It doesn't make sense to measure fitness in isolation, as we have done so far,
by looking at individual fights. Instead, we need to consider the individual's
surroundings. A single hawk in a population of doves will have an easy life,
winning all fights with maximum payoff. Intuitively, this translates to a high
fitness.

In a few paragraphs we will see how to compute the fitness starting from the
payoffs. But for now, let's begin by examining the _weighted average payoffs_ of
fights, which takes into account the opponent's frequency in the population.

```python
population_size = 100
n_hawks = 1
population = [Strategy.HAWK] * n_hawks + [Strategy.DOVE] * (population_size - n_hawks)
assert len(population) == population_size
split = collections.Counter(population)

payoffs_matrix = simulate(population, n_fights=10000)
print(f"Population by species: {split}")
# >>> Population by species: Counter({DOVE: 99, HAWK: 1})

weighted_avg_payoffs = {}
for species, averaged_payoffs_by_species in payoffs_matrix.items():
    # 👇 For each species:
    # - Take the expected payoff per fight (against each other species)
    # - Weight it by the adversary's _frequency_ in the population
    weighted_avg_payoffs[species] = mean(
        avg * split[s] / len(population)
        for s, avg in averaged_payoffs_by_species.items()
    )
#                                                  👇
# >>> Weighted average payoff: {DOVE: 7.425, HAWK: 49.5}
```

As expected, a solitary hawk thrives among all doves.

However, as the number of hawks increases, their chances of fighting each other
and suffering serious injuries increases too. Their payoff (and their fitness)
decline.

```python
# Make this a function to re-use it easily
def weighted_average_payoffs(payoffs_matrix, split) -> dict[Strategy, float]:
    w_avg_payoffs = {}
    # [...]
    return w_avg_payoffs


population_size = 100
#         👇
n_hawks = 25
population = [Strategy.HAWK] * n_hawks + [Strategy.DOVE] * (population_size - n_hawks)
assert len(population) == population_size
split = collections.Counter(population)
print(f"Population by species: {split}")
# >>> Population by species: Counter({DOVE: 75, HAWK: 25})

payoffs_matrix = simulate(population, n_fights=10000)
w_avg_payoffs = weighted_average_payoffs(payoffs_matrix, split)
print(f"Weighted average payoff: {weighted_average_payoffs}")
#                                                  👇
# >>> Weighted average payoff: {DOVE: 5.625, HAWK: 15.625}
```

In this scenario the weighted average payoff for hawks decreases to 15.625 (from
49.5).

How does it change according to the frequency of hawks in the population?

{:.text-align-center}
![frequency of hawks and doves in the population against weighted average payoff](../images/hawks_by_frequency.svg){:.centered}
_Frequency of hawks and doves in the population against weighted average payoff._

The weighted average payoffs of the two species intersect! And as it often
happens, cool things occur at the intersection.

### Evolutionarily Stable Strategies (ESS)

In this case, the intersection represents a point of _equilibrium_. When the
population consists of ~58.3% (more precisely, 7/12) hawks and 5/12
doves[^params], the average weighted payoff for doves _matches_ that of hawks.
What does this mean? It means we have found an "[Evolutionarily stable
strategy](https://en.wikipedia.org/wiki/Evolutionarily_stable_strategy)" (ESS).

_In informal terms_ (remember, I am a computer scientist stepping into biology
🧑‍🔬), an ESS means that once a population adopts this (mix of)
strategy(ies), it will resist _invasions_ from other (sets of) strategies.

We have now mentioned the word "evolutionary" a few times, so let's bring the
big guns in. So far, we haven't considered the role of "evolution". Instead, we
have just enumerated the different hawk-to-dove ratios in the population and
found an ESS through brute force. What's truly fascinating is that _individual
selection_ will lead us to the ESS.

Here is how it works. Imagine that the population under our glass bell is 50%
doves and 50% hawks. Referring to the plot above, we know that the weighted
average payoff for hawks, at 50% split, is higher that doves'. In other words,
hawks will have better access to resources and better chances of reproduction.
Consequently, the next generation under our bell will count more hawks than
doves (for instance, 55% vs 45%). We are _descending_ along the slope of the
orange line.

Now consider another scenario, where there are too many hawks. Competition is
fierce and fights among hawks end with severe injuries. In contrast, doves back
off from fights against hawks and enjoy a better expected payoff. This
translates to improved chances of reproduction, leading to the next generation
having more doves and fewer hawks (_ascending_ along the blue line).

### Weighted Average Payoff → Fitness

At this point we have almost all we need to _do the evolution_. The final
ingredient involves converting the weighted average payoff into _fitness_, to
express the likelihood of reproducing. Since a payoff can be negative, we can't
use it directly as a probability, nor as the expected number of offspring --
what would it mean to have -3 children?

However, we can use a little imagination. Our goal is for species with a
_positive_ weighted average payoff to have better reproduction chances than
those with a _negative_ value. I approached this as follows (but there might be
better solutions):

- Separate positive and negative payoffs.
- Apply
  [min-max](<https://en.wikipedia.org/wiki/Feature_scaling#Rescaling_(min-max_normalization)>)
  to the negative payoffs, normalizing them between 0 and 1.
- Apply the same normalization to positive payoffs, but add +1 to the result,
  normalizing them between 1 and 2.

Intuitively, this method works because we have centered the results around 1
(the neutral element of multiplication). We will use them as follows. Imagine
there were initially 43% hawks. Their average weighted payoff was positive, and
so their _fitness_ is greater than 1. By multiplying 43% by their fitness (>1),
we obtain a higher frequency of hawks in the new generation. A _fitness_ below 1
would, instead, _shrink_ the number of hawks in the population.

The following snippet implements this logic.

```python
def scale(d, min_payoff, max_payoff):
    # negative numbers to 0..1
    # positive numbers to 1..2
    assert min_payoff < 0
    if min_payoff < 0 and abs(min_payoff) > max_payoff:
        max_payoff = abs(min_payoff)

    # Made very verbose for explainability.
    r = {k: (v - min_payoff) / (0 - min_payoff) for k, v in d.items() if v < 0} | {
        k: (1 + v - 0) / (max_payoff - 0) for k, v in d.items() if v > 0
    }
    assert all(0 <= v <= 2 for v in r.values())
    return r
```

### Simulating individual selection

We can finally _simulate individual selection_. We begin with a population equally
divided between hawks and doves. Then, we evolve it gradually by relying on
individual fitness (remember, fitness depends on the population split!).

```python
population_size = 10000
n_generations = 125
results = []
population = [Strategy.HAWK] * (population_size // 2) + [Strategy.DOVE] * (
    population_size // 2
)
payoffs_matrix = simulate(population)
min_payoff = min(p.value for p in Points)
max_payoff = max(p.value for p in Points)

for i in range(n_generations):
    split = collections.Counter(population)
    results.append(split)

    w_avg_payoffs = weighted_average_payoffs(payoffs_matrix, split)

    # scale to 0...1...2
    scaled_w_avg_payoffs = scale(w_avg_payoffs, min_payoff, max_payoff)

    # multiply by frequency to compute fitness
    absolute_fitness = {
        k: split[k] * v / population_size for k, v in scaled_w_avg_payoffs.items() }

    # evolve to the next generation
    population = random.choices(
        tuple(absolute_fitness.keys()),
        weights=tuple(absolute_fitness.values()),
        k=population_size,
    )
```

Here is the plot resulting from a run of the simulation.

{:.text-align-center}
![frequency of hawks and doves in the population as generations evolve](../images/hawks_by_generation.svg){:.centered}
_Frequency of hawks and doves in each generation, as they evolve._

This particular simulation took less than 10 generations to reach the ESS,
highlighted by the red line at 58.3% (the 7/12 ratio we have previously
discovered through brute force). Our hand-crafted _fitness function_ provides a
good indicator for _individual selection_, leading the proportion of hawks to
doves to _quickly_ reach the equilibrium.

Once at the equilibrium, the strategy resists invasion. Evolution continues and
slightly changes the percentage of hawks and doves in the population, but their
frequency reverts to the ESS. Again, informed by our fitness function.

Our experimental results show the definition of ESS being applied _in practice_.
From [above](#evolutionarily-stable-strategies-ess):

> ESS means that once a population adopts this (mix of)
> strategy(ies), it will resist _invasions_ from other (sets of) strategies.

The ESS _resists_ changes to the population split that would result in less
favorable payoffs. Notably, one can think of a "population split" as a strategy
where the individual privately tosses a biased coin before each fight to decide
whether to behave like a hawk or a dove. In these terms, our ESS:

- Resists invasion from strategies bias differently from 7:12, in favor of
  hawks.
- Performs well against itself. In fact, this is an alternative definition for
  ESS: a strategy that "does well" against copies of itself.

## Conclusions

We've covered a lot of ground, starting from the high-level definition of
fitness to arrive at simulating individual selection.

Armed with these tools there's so much more we can experiment about! Other
interesting strategies, for example. How about someone who _retaliates_,
fighting back only if attacked? Check the [references](#references) for a sneak
peek.

👋 That's it for today! Thank you for reading so far.

<div class="note" markdown="1">
One last thing: I can't leave you without pointing you to the soundtrack I had
in mind all along.
<br>🎧 [Do the Evolution - Pearl Jam](https://www.youtube.com/watch?v=aDaOgu2CQtI)
</div>

## References

- Smith, J., Price, G. The Logic of Animal Conflict. Nature 246, 15–18 (1973).
  [https://doi.org/10.1038/246015a0](https://www.nature.com/articles/246015a0)
- Gale, J. S., & Eaves, L. J. (1975). Logic of animal conflict. Nature,
  254(5499), 463–464.
  [https://doi.org/10.1038/254463b0](https://psycnet.apa.org/doi/10.1038/254463b0)

The paper by Smith and Price, cited by Dawkins, originally introduced
evolutionary game theory.

It formulates a slightly different version of our problem by swapping "dove"
with "mouse". Instead of describing fights only through their outcome, the
authors describe the steps leading to the outcome ("provoke", "attack", and so
on). Lastly, they introduce additional strategies for a "bully", a "retaliator",
and a "prober-retaliator". "Retaliator" is supposed to be an ESS.

In 1975, Gale and Eaves showed through computer simulation (!) that "retaliator"
is in fact not an ESS. A "dove" in a population of "retaliator" behaves like a
"retaliator" and, therefore, can invade it.

## Footnotes

[^40th]: 40th Anniversary edition, published by Oxford Landmark Science.
[^doves]:
    This dove is different from the animal we know, who is in fact quite
    an aggressive species.

[^neil_young]:
    Unrelated from [Neil Young's
    album](https://en.wikipedia.org/wiki/Hawks_%26_Doves). Still a great record
    though.

[^params]:
    The numbers 5/12 and 7/12 are not "magic", nor general. They
    specifically depend on the scores we attribute to the fight outcomes.
