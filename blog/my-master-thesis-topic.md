---
title: My master thesis topic
date: 2026-03-14
tags:
  - Scientific Computing
  - Neuron Models
  - Python
---

# What is your thesis about?

My family never asked me what the topic of my master thesis is.
I assume they're too scared to not be able to understand anything I'm talking about; however, I don't think it's necessarily very complicated.
To quote Richard Feynman: 'If you can't explain it simply, you don't understand it well enough.'
So let's see if I understand what I'm talking about.

Scientific Computing is the intersection between computer science, mathematics and natural sciences.
We try to simulate the real world on a computer.
I think, non-computer scientists don't have a good idea about how hard or easy it is to simulate something.
PETA, for example, is fighting to stop Animal Testing by replacing it with [Computer Modeling](https://www.peta.org/issues/animals-used-for-experimentation/alternatives-animal-testing/).
To be fair, they just name it as one alternative, however, I think it's a good starting point to try to understand how computer simulations work.
And to be frank, the complexity of simulations can hugely differ, even if the underlying principles remain the same.

## What is Scientific Computing?

Between theory and experiment, simulations can be seen as the third pillar of science.
Theories must be able to predict the future, experiments therefore can help invalidate them by proving that expectations were not fulfilled.
However, experiments are not always feasible.
It could be that they are impossible (e.g. testing the collision of two galaxies), unwanted (e.g. how oil disperses in the ocean if an oil platform had a leak) or simply too expensive.
But how does a simulation work?

It starts with a phenomenon or process that we are trying to understand.
We then start modelling and obtain a mathematical description of the phenomenon.
These usually consist of one or multiple equations that describe a system --- or more likely: how a system changes.
This is what is then solved on the actual computer; however, numerical solving algorithms can vastly vary in complexity, computational efficiency and quality of the obtained solution.
Important to note is that we need to be able to obtain these mathematical descriptions.
Depending on the complexity of the system, it might be enough to have the physical equations.
However, when for example simulating neurons in the brain, it is simply unfeasible to simulate each atom moving around.
We need more abstract descriptions of these systems --- this is sometimes really difficult.
To simulate something before having some good understanding of it is therefore easier said than done.

Luckily, for neurons specifically, a variety of these descriptions have been developed over the years.
The one I'm dealing with in the context of my master thesis is called: Adaptive Exponential Leaky Integrate-and-Fire Model (cool, right?).
This model describes how neuron behaviour works in general; however, there exist a huge number of neurons in the brain, all behaving very differently.
When stimulated, some fire rapidly and steadily.
Others start with a burst of spikes and then need a break before they can spike again.
Yet other neurons start slow and ramp up to higher frequencies.
The point is, the model needs to be tuned to match a specific neuron type.
It's like getting a pair of glasses.
You find a model you like, but it then needs to be tweaked to fit to you specifically.

I'm trying to do this in a quick and efficient way.
For the AdEx-Model specifically.
There you go, that's my master thesis topic.
Wasn't that bad, was it?

