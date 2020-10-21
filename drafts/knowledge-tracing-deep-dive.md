https://supermemo.guru/wiki/Neural_networks_in_spaced_repetition
"Any further fine-tuning of the algorithms, applying artificial intelligence or neural networks would be drowned in the
noise of interference. After all, we do not learn in isolation from the world. When the program schedules the next
repetition in 365 days, and the fact is recalled by chance at an earlier time, SuperMemo has no way of knowing about the
accidental recollection and will execute the repetition at the previously planned moment. This is not optimal, but it
cannot be remedied by improving the algorithm. Improving SuperMemo now is like fine tuning a radio receiver in a noisy
car assembly hall."



# Knowledge Tracing and Spaced Repetition Deep Dive

Knowledge tracing is the act of predicting how well you know a concept or how well you'll be able to answer a particular
question given a history of interactions. As a long time spaced repetition Anki user, I'm personally very interested in this in this
problem, because I think it can be greatly improved.

Anki is a flashcards application which employs Spaced Repetition in order to optimally schedule repetitions of cards.
Spaced Repetition builds upon two observations about memory:

1. The probability of forgetting follows the exponential distribution, with memory strength, or memory _half-life_ being
   the only parameter
2. The longer you wait to review an item while still successfully retrieving it, the stronger the increase of memory
   strength. This increase is roughly double

The inverse of the cumulative exponential distribution becomes the famous "forgetting curve":

...

The question is, what goes into this magic _half-life_ number? 

It's well known that you can minimize the time you needed for studying a piece of information by spacing the repetitions
further and further apart, in an exponential fashion. 

Ebbinghaus
experimented on himself by trying to memorize meaninless strings of symbols and trying to find a mathematical model for
the probability of forgetting. His experiments concluded that the probability of forgetting follows the _exponential
distribution_, which is on the form:

$$ e^(-t/\lambda) $$

Where \lambda is the half-life 



# Memory Chain Model
The memory chain model posits multiple memory banks ...

We have two memory stores with different half-lifes, h1 and h2, h2 >> h1. Memories are copied from the first store to
the seconds store, but we estimate this by using an RNN to directly update h1 and h2.

The probability of recall is then 1 - (1 - P(r_0)*(1 - P(r_1)) = 1 - 1 - P(r_1) - P(r_0) + P(r_0)P(r_1) = P(r_0)P(r_1) - P(r_1) - P(r_0)
The 


Reviewing a piece of information, we update both. Reviewing an item with low resonance, we'd set h1 


