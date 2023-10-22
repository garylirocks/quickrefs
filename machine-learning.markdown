# Machine Learning

- [Linear regression](#linear-regression)
  - [Cost function](#cost-function)
  - [Gradient descent](#gradient-descent)
- [Multiple linear regression](#multiple-linear-regression)
  - [The model](#the-model)
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

Notations:

- $x_j$ : $j^{th}$ feature
- $n$ : number of features
- $\vec{x}^{(i)}$ : features of $i^{th}$ training example
- $\vec{x}_j^{(i)}$ : value of feature $j$ in $i^{th}$ training example

### The model

$$f_{w,b}(\vec{x}) = w_1x_1 + w_2x_2 + \dots + w_nx_n + b$$

or in vector form:

$$f_{\vec{w},b}(\vec{x}) = \vec{w} \cdot \vec{x} + b$$

where

- $\vec{w} = \begin{bmatrix}w_1 \\ w_2 \\ \vdots \\ w_n\end{bmatrix}$, $\vec{x} = \begin{bmatrix}x_1 \\ x_2 \\ \vdots \\ x_n\end{bmatrix}$

- $\cdot$ means **dot product** in linear algebra

In code with NumPy:

```python
f = np.dot(w, x) + b
```



## References

[Machine Learning | Coursera](https://www.coursera.org/specializations/machine-learning-introductIon)