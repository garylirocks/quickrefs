# Reinforcement Learning

## Concepts

![Concepts](images/ml_reinforcement-learning-concepts.png)

- "reward" is for each state
- "return" is for the overall action sequence
- "policy $\pi$" decides the next action based on current state: $\pi(s) = a$

![MDP - Markov Decision Process](images/ml_markov-decision-process.png)

*The key feature is that the action SOLELY depends on current state, not how you got here*

### State-action value function (Q function)

![State-action value function](images/ml_state-action-value-function.png)

- *For each state, you should take the action that maximizes the return*
- $Q$ is sometimes referred to as $Q^*$

This can be written as the **Bellman Equation**

$$ Q(s, a) = R(s) + \gamma\max\limits_{a'}Q(s', a') $$

*$s'$ (s prime) is the next state you get taking action $a$ from current state $s$*

In a **random (stochastic) environment**, you can't fully control the action taken in each step (you want to move to the left, but there's a possibility that it ends up going right), you need to modify the equation a bit:

$$ Q(s, a) = R(s) + \gamma E[\max\limits_{a'}Q(s', a')] $$

*$E$ means the expected value*