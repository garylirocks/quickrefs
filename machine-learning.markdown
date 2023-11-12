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
  - [Cost function](#cost-function-1)
  - [Gradient descent](#gradient-descent-1)
- [Overfitting](#overfitting)
  - [Regularization](#regularization)
- [Neural networks](#neural-networks)
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

$$f_{\vec{w},b}(\vec{x}) = g(\vec{w} \cdot \vec{x} + b) = \frac{1}{1 + e^{-(\vec{w} \cdot \vec{x} + b)}}$$

Can also view it this way, given input $\vec{x}$ and parameters $\vec{w}$, $b$, the probability that $y$ equals 1:

$$f_{\vec{w},b}(\vec{x}) = P(y=1|\vec{x};\vec{w},b)$$

When $z$ or $\vec{w} \cdot \vec{x} + b = 0$, $g(z)$ is 0.5, the probability for either positive or negative result is 0.5, this is called the **decision boundary**.

NOTE: $w$ and $b$ won't be the same if you run linear regression and logistic regression on the same data set

![Logistic regression non linear decision boundary](images/ml_logistic-regression-decision-boundary-non-linear.png)

*With high order polynomial function, the decision boundary does not need to be linear*

### Cost function

The squared error function is not suitable in classification scenarios, the resulting cost function do not produce a convex curve.

We use the logistic loss function

*Loss means the difference from prediction to target for a paticular example*

$$
L(f_{\vec{w},𝑏}(\vec{X}^{(i)}), y^{(i)}) =
\begin{cases}
    −\log{\left( f_{\vec{w},𝑏}(\vec{X}^{(i)}) \right)} & \text{if } y^{(i)} = 1 \\
    −\log{\left( 1 - f_{\vec{w},𝑏}(\vec{X}^{(i)}) \right)} & \text{if } y^{(i)} = 0
\end{cases}
$$

To simplify it, we can combine the two cases to just one formula:

$$L(f_{\vec{w},𝑏}(\vec{X}^{(i)}), y^{(i)}) =  −y^{(i)}\log f_{\vec{w},𝑏}(\vec{X}^{(i)}) - (1−y^{(i)}) \log (1 - f_{\vec{w},𝑏}(\vec{X}^{(i)})) $$

The cost function is

*Cost means the average loss for the total dataset*

$$
J(\vec{w},b) = \frac{1}{m} \sum_{i=1}^m { \left[ L(f_{\vec{w},𝑏}(\vec{X}^{(i)}), y^{(i)}) \right] } \\
= - \frac{1}{m} \sum_{i=1}^m { \left[ y^{(i)}\log f_{\vec{w},𝑏}(\vec{X}^{(i)}) + (1−y^{(i)}) \log (1 - f_{\vec{w},𝑏}(\vec{X}^{(i)})) \right] } \\
$$

The closer the predicted value is to the actual value (0 or 1), the less the loss:

![Logistic regression loss function 1](images/ml_logistic-loss-function-1.png)
![Logistic regression loss function 2](images/ml_logistic-loss-function-2.png)
![Logistic regression cost function](images/ml_logistic-cost-function.png)

### Gradient descent

$$
\begin{align*}
&\text{repeat until convergence:} \; \lbrace \\
&  \; \; \;w_j = w_j -  \alpha \frac{\partial J(\mathbf{w},b)}{\partial w_j} \tag{1}  \; & \text{for j := 0..n-1} \\
&  \; \; \;  \; \;b = b -  \alpha \frac{\partial J(\mathbf{w},b)}{\partial b} \\
&\rbrace
\end{align*}
$$

Where each iteration simultaneously updates $w_j$ for all $j$, where

$$
\begin{align*}
\frac{\partial J(\mathbf{w},b)}{\partial w_j}  &= \frac{1}{m} \sum\limits_{i = 0}^{m-1} (f_{\mathbf{w},b}(\mathbf{x}^{(i)}) - y^{(i)})x_{j}^{(i)} \tag{2} \\
\frac{\partial J(\mathbf{w},b)}{\partial b}  &= \frac{1}{m} \sum\limits_{i = 0}^{m-1} (f_{\mathbf{w},b}(\mathbf{x}^{(i)}) - y^{(i)}) \tag{3}
\end{align*}
$$


## Overfitting

If you use a high order polynomial model, a model may fit the training data perfectly, the cost is zero. But the model would not generalize well, meaning it does not work well with new data.

Overfitting is also called **high variance**.

![Overfitting](images/ml_overfitting.png)

Three ways to address overfitting:

- Collect more data
- Select features
- Regularization: Reduce size of parameters

### Regularization

The equation for the cost function regularized linear regression is:

$$J(\mathbf{w},b) = \frac{1}{2m} \sum\limits_{i = 0}^{m-1} (f_{\mathbf{w},b}(\mathbf{x}^{(i)}) - y^{(i)})^2  + \frac{\lambda}{2m}  \sum_{j=0}^{n-1} w_j^2 \tag{1}$$

Comparing to the normal linear regression, the difference is the regularization term,  <span style="color:blue">$\frac{\lambda}{2m}  \sum_{j=0}^{n-1} w_j^2$ </span>

Including this term encourages gradient descent to minimize the size of the parameters.

*Note, in this example, the parameter $b$ is not regularized. This is standard practice.*


## Neural networks

![Neural network layers](images/ml_neural-network-layers.png)

![Neural network notations](images/ml_neural-network-layers-notations.png)

Each layer contains multiple neurons(AKA units, activation functions), each of them is a logistic regression model.

Build a neural network in TensorFlow:

![Use TensorFlow to build a neural network](images/ml_neural-network-tensorflow.png)

```python
A = np.array([[200, 17],
              [120, 5],
              [425, 20],
              [212, 18]])
# with known weights for layer1
W1 = np.array([[1, -3, 5],
               [-2, 4, -6]])
B1 = np.array([[-1, 1, 2]])

# with matrix multiplication, the first layer computation is like
def dense(A, W, b):
  z = np.matmul(A, W) + b
  a_out = g(z)
  return a_out
```


## References

[Machine Learning | Coursera](https://www.coursera.org/specializations/machine-learning-introductIon)