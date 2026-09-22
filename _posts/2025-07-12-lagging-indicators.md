---
title: 'Paddling in circles: lagging indicators'
excerpt: >
  🛶 Thinking in systems through models, loops, and delays.
---

Last weekend I went kayaking on the [Ardèche
river](https://en.wikipedia.org/wiki/Ard%C3%A8che_(river)), in southern France.
I had kayaked a couple of times before, but never in tandem over a two-day trip.
It was a terrific experience, with wonderful people in mesmerizing nature.

As it often happens when I do outdoor sports, my mind put together a few
thoughts. This time, about systems, their delays, and lagging indicators. I
think they generalize to more than kayaks 🛶, so I wrote about them here.

{:.text-align-center}
![The Ardèche river, its rocky borders, four kayaks navigating it and an angle of sky.](../images/GOPR3224.webp){:.centered}

For most of day one (out of two), my kayak partner and I struggled to navigate
in a straight line. We often found the kayak pointing at the wrong angle and
had to bring it back on route. Then, we would find it pointing wrongly in the
_other_ direction. Unsurprisingly, we reached camp for the night tired and with
low morale.

_Why_ were we doing such a bad job? Because of _delays_! 

{:.text-align-center}
![A diagram of a kayak showing the effect of paddling (forward and to the side)](../images/kayak.svg){:.centered.inverted}

A kayak:

1. Gains forward speed when pushed by the paddle, backwards, on either side.
2. Turns in the opposite direction of the paddle in the water.

These forces complement each other. Paddling on the right side will move the
kayak forward and point it slightly to the left. Paddling on the left will
offset the change in direction while maintaining the speed. This is why you
typically alternate paddling on each side: to maintain momentum and balance the
forces that would rotate the kayak.

Occasionally, things did not work that way for us. When the kayak leaned
one way, we paddled "harder" on that side to turn in the opposite direction.
But, by then, it was too late already! Due to the _delay_ between the
energy we transmitted to the water and the kayak rotating, the kayak's
direction was a _lagging indicator_ of the quality of our efforts. 

The kayak in the water is a _system_ we can model, reason about, and _predict_.
Because no reaction is truly instantaneous, _all systems_ have delays. Knowing
where they are and how to shorten (or lengthen) them means finding a leverage
point that can affect the whole system. Therefore, learning how to operate in
the absence of timely information is key: both to having fun on a kayak and to
making better decisions in business and life. When I realized that, the task of
controlling a kayak looked a lot like a scaled-down version of the challenges
we face daily and I saw an opportunity for thinking about it and
connecting the dots.

> We can’t begin to understand the dynamic behavior of systems unless we know
> where and how long the delays are. And we are aware that some delays can be
> powerful policy levers. Lengthening or shortening them can produce major
> changes in the behavior of systems.
>
> Thinking in Systems, A Primer. By Donella H. Meadows

On the kayak, we went through phases of observation and experimentation. At
first, we suspected that an asymmetry in our paddling (left/right or
front/back) was at fault. We thought that if we could have perfectly symmetric
strokes, then the kayak would go straight. But then, how would we account for
the remaining factors, e.g. the water currents? We wanted to build a mental
model of the kayak so that we could diagnose our troubles and figure out how to
fix them. But we were failing, because delays were muddling the effects of our
inputs and revealing them only after some time (when the kayak turned).

{:.text-align-center}
![A diagram of a kayak showing how delays and other forces make it harder to predict the effect of paddling.](../images/kayak-delays.svg){:.centered.inverted}

To get better, we had to first acknowledge that the system was _messier_ than
what we were trying to picture in our minds. Both delays and external forces
were contributing to the outcome. Once we learned that, we started to master
our waters. We started looking at _weaker_ observations that were more readily
available: e.g., our bow _just hinting_ at a direction after a
paddle stroke. This way, we shortened the feedback loop of actions,
measurements, and reactions and we stopped over-correcting our angle when it
was too late. With experience, we even started _seeing_ how each paddle stroke
would slightly turn the kayak while pushing it forward and we learned how to
naturally balance for that in the next stroke. We could "point" the kayak more
effectively, control our route and pick between more options in how to face the
rapids. And, obviously, have a ton more fun!

So, what did we learn?

1. The map is not the territory. We have a natural tendency to build _tidy_
   mental models, but the world is sometimes messier than that. Acknowledge
   that to iteratively build a useful model.
1. All systems have delays, since no reaction is truly instantaneous. Delays
   lead to oscillations and longer feedback loops, which make systems harder to
   "hold in the head". 
1. Delays are powerful leverage points. Controlling them can result in
   significant (sometimes surprising) changes to the system's behavior.
1. A faster loop reduces the effect of delays, which makes it easier to
   understand the system.
1. The shorter the loop, the faster we iteratively build system models. Strive
   for simplicity, get it working, then improve it through experience and
   insights.
1. If something is hard to predict (or correct), you might be only looking at
   _lagging indicators_. They are more visible but less useful than _leading
   indicators_. A weaker signal _earlier_ on is useful: try looking for those
   leads.

These lessons apply across disciplines. Software development, for instance,
combines different loops (write, review, bugfix, or release, deploy, rollback)
and leading and lagging indicators (number of developers vs number of bugs
released). There are delays: it takes time for a developer to onboard and
become an effective contributor; sometimes, bugs only surface years after they
have been coded. It is also _messy_: we measure team velocity and story points,
but need to acknowledge how reality changes around us and the humans that
compose the team. Endurance training can be another example. It takes weeks to
build the aerobic skills required to compete and training and recovery interact
in loops (with form and fitness). The heart rate on race day is a leading indicator,
while [VO₂ max](https://en.wikipedia.org/wiki/VO2_max) lags behind.

I hope that while reading about delays and indicators you started picturing
examples from your own fields where these thoughts apply. Reach out through the
contacts in the footer; I would love to hear all about it!

Thank you for reading, and until next time! 👋
