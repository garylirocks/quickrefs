# Machine Learning

- [Linear regression](#linear-regression)
  - [Cost function](#cost-function)
  - [Gradient descent](#gradient-descent)
- [Multiple linear regression](#multiple-linear-regression)
  - [The model](#the-model)
  - [Gradient descent for multiple variables](#gradient-descent-for-multiple-variables)
  - [Feature scaling](#feature-scaling)
- [Feature engineering](#feature-engineering)
- [Logistic regression](#logistic-regression)
- [References](#references)


## Linear regression

### Cost function

With a linear model

$f_{w,b}(x) = w * x + b$

the cost function is defined as:

$$J(w,b) = \frac{1}{2m} \sum_{i=1}^m {\left( f_{w,b} (x^{(i)}) - y^{(i)} \right)}^2 $$

- $x^{(i)}$ the $i$th input, NOT the $i$th power of $x$
- $y^{(i)}$ the $i$th output
- $f_{w,b} (x^{(i)}) - y^{(i)}$ : error at point $i$
- $f_{w,b}(x)$ : could also be written as $f(x)$ or $\hat{y}$ ($y$ hat), which is the calculated/estimated value of $y$
- `J` cost function
- `m` number of data points
- `w` weight
- `b` bias

Because we are using squared error, so $J$ is always positive, and is a bowl shape in a 3D graph.

The goal is to find values of $w$ and $b$, which will minimize the value of $J$

$$\min\limits_{w,b}J(w, b)$$

### Gradient descent

Gradient descent is an algorithm to find the minimum of a function. It not only works for just one weight parameter $w$

$$\min\limits_{w,b}J(w, b)$$

, but also for multiple parameters $w_1,w_2,\dots,w_n$

$$\min\limits_{w_1,w_2,\dots,w_n,b}J({w_1,w_2,\dots,w_n,b})$$

The algorithm is as follows:

1. Start with random values for $w$ and $b$, such as $w=0$, $b=0$
2. Assign new values
    $$w = w - \alpha\frac{\partial}{\partial{w}}J(w, b)$$
    $$b = b - \alpha\frac{\partial}{\partial{b}}J(w, b)$$

    - $\alpha$ is the **learning rate**, which is a small positive number, such as 0.01, if it's too small, it will take a long time to converge, if it's too large, it may overshoot (not converge)
    ![Convergence vs. overshoot](./images/ml_gradient-descent.png)

    - $\frac{\partial}{\partial{w}}J(w, b)$ is the partial derivative with respect to $w$, ie. a small change of $J(w, b)$ divided by a small change of $w$

    $$\frac{\partial}{\partial{w}}J(w,b) = \frac{1}{m} \sum_{i=1}^m {\left( f_{w,b} (x^{(i)}) - y^{(i)} \right)}x^{{i}}$$

    $$\frac{\partial}{\partial{b}}J(w,b) = \frac{1}{m} \sum_{i=1}^m {\left( f_{w,b} (x^{(i)}) - y^{(i)} \right)}$$

3. Repeat until convergence, ie, the value of $J$ is not changing much


## Multiple linear regression

![Multiple features](images/ml_multiple-features.png)

| General Notation        | Description                                                                          | Python (if applicable) |
| ----------------------- | ------------------------------------------------------------------------------------ | ---------------------- |
| 𝑎                       | scalar, non bold                                                                     |
| 𝐚                       | vector, bold                                                                         |
| 𝐀                       | matrix, bold capital                                                                 |
| 𝐗                       | training example matrix                                                              | `X_train`              |
| 𝐲                       | training example targets                                                             | `y_train`              |
| 𝐱(𝑖), 𝑦(𝑖)              | 𝑖𝑡ℎ Training Example                                                                 | `X[i]`, `y[i]`         |
| m                       | number of training examples                                                          | `m`                    |
| n                       | number of features in each example                                                   | `n`                    |
| 𝐰                       | parameter: weight                                                                    | `w`                    |
| 𝑏                       | parameter: bias                                                                      | `b`                    |
| 𝑓𝐰,𝑏(𝐱(𝑖))              | The result of the model evaluation at 𝐱(𝐢) parameterized by 𝐰,𝑏: 𝑓𝐰,𝑏(𝐱(𝑖))=𝐰⋅𝐱(𝑖)+𝑏 | `f_wb`                 |
| $\frac{∂𝐽_(𝐰,𝑏)}{∂𝑤_𝑗}$ | the gradient or partial derivative of cost with respect to a parameter $w_j$         | `dj_dw[j]`             |
| $\frac{∂𝐽_(𝐰,𝑏)}{∂𝑤_b}$ | the gradient or partial derivative of cost with respect to a parameter $b$           | `dj_db`                |

Notations:

- $x_j$ : $j^{th}$ feature
- $n$ : number of features
- $\vec{x}^{(i)}$ : features of $i^{th}$ training example
- $\vec{x}_j^{(i)}$ : value of feature $j$ in $i^{th}$ training example

### The model

$$f_{w,b}(\vec{x}) = w_1x_1 + w_2x_2 + \dots + w_nx_n + b$$

or in vector form:

$$f_{\vec{w},b}(\vec{x}) = \vec{w} \cdot \vec{x} + b$$

or in NumPy

```python
f = np.dot(w, x) + b
```

where

- $\vec{w} = \begin{bmatrix}w_1 \\ w_2 \\ \vdots \\ w_n\end{bmatrix}$, $\vec{x} = \begin{bmatrix}x_1 \\ x_2 \\ \vdots \\ x_n\end{bmatrix}$

- $\cdot$ means **dot product** in linear algebra

### Gradient descent for multiple variables

![Gradient descent for multiple variables](images/ml_gradient-descent-multipe-variables.png)

### Feature scaling

This is to make the features have similar scale (usually -1 to 1), so that the gradient descent will converge faster.

After normalization, `0.1` is a good start for the learning rate $\alpha$.

Three techniques:

- Feature scaling

  $$x_i = \frac{x_i - min}{max - min}$$

- Mean normalization

  $$x_i = \frac{x_i - \mu_i}{max - min}$$

- Z-score normalization

  $$x_i = \frac{x_i - \mu_i}{\sigma_i}$$

  - $\mu_i$ : mean of feature $i$
  - $\sigma_i$ : standard deviation of feature $i$
  - The scaled feature will have a mean of 0 and standard deviation of 1


## Feature engineering

![Feature engineering](images/ml_concept-feature-engineering.png)

- Creating new features from existing features.
- You should do feature scaling after feature engineering.


## Logistic regression

![Logistic regression model](images/ml_concept-logistic-regression.png)

The model uses sigmoid function (aka logistic function), which takes the the linear regression model's output as input, then outputs a value between 0 and 1, it's like transforming a straight line to an "S" shaped curve.

Can also view it this way, given input $\vec{x}$ and parameters $\vec{w}$, $b$, the probability that $y$ equals 1:

$$f_{\vec{w},b}(\vec{x}) = P(y=1|\vec{x};\vec{w},b)$$

When $z$ or $\vec{w} \cdot \vec{x} + b = 0$, $g(z)$ is 0.5, the probability for either positive or negative result is 0.5, this is called the **decision boundary**.

NOTE: $w$ and $b$ won't be the same if you run linear regression and logistic regression on the same data set

![Logistic regression non linear decision boundary](images/ml_logistic-regression-decision-boundary-non-linear.png)

*With high order polynomial function, the decision boundary does not need to be linear*


## References

[Machine Learning | Coursera](https://www.coursera.org/specializations/machine-learning-introductIon)