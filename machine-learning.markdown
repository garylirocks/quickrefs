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
  - [Learning curve](#learning-curve)
  - [Regularization](#regularization)
- [Neural networks](#neural-networks)
  - [Activation functions](#activation-functions)
  - [ReLU](#relu)
  - [Multiclass classification](#multiclass-classification)
  - [Convolutional layer](#convolutional-layer)
  - [Bias and variance](#bias-and-variance)
- [Model validation](#model-validation)
  - [Technics](#technics)
- [Decision tree](#decision-tree)
  - [Entropy function](#entropy-function)
  - [Regression tree](#regression-tree)
  - [Tree ensembles](#tree-ensembles)
  - [XGBoost](#xgboost)
- [Skewed dataset](#skewed-dataset)
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

- **Underfitting**
  - also called **high bias**
  - training set error $J_{train}$ is large
- **Overfitting**
  - also called **high variance**
  - usually happens with a high order polynomial model
  - cross validation error $J_{cv}$ is much larger than $J_{train}$

![Overfitting](images/ml_overfitting.png)

Ways to fix underfitting (high bias):

- Try getting additional features
- Try adding polynomial features ($x_1^2$, $x_2^2$, $x_1x_2$, etc)
- Try decreasing $\lambda$

Three ways to address overfitting:

- Collect more data
- Try smaller set of features
- Regularization: increasing $\lambda$, reduce size of parameters

### Learning curve

![Learning curve](images/ml_learning_curve.png)

How does the training and cross validation errors change in relation to the sample size
- More samples usually can reduce CV errors
- The training error (bias) may plateau and won't improve with increasing sample size

### Regularization

The equation for the cost function of regularized linear regression is:

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

### Activation functions

Neural network needs activation functions, if you just use linear regression in every layer, the effect is no different than using linear regression directly.

Common activation functions:

- Linear activation function (aka no activation function) $g(z) = z$
- Sigmoid $g(z) = \frac{1}{1 + e^{-(z)}}$
- ReLU (Rectified Linear Unit) $g(z) = max(0, z)$

![Activation functions](images/ml_neural-network-activation-functions.png)

Choosing activation function:

- Output layer:
  - Binary classification: Sigmoid
  - Prediction could be positive or negative: Linear
  - Prediction can only be positive: ReLu
- Hidden layers:
  - **ReLU** is the most common choice today
  - Sigmoid used to be popular, but it's slower to compute and learn

### ReLU

When multiple ReLU functions are composed together, each could contribute a section to the output, making the output non-linear, that's why it's helpful.

![ReLU composing](images/ml_neural-network-relu.png)

### Multiclass classification

![Multiclass classification](images/ml_neural-network-multiclass-softmax.png)

Using the Softmax as the output activation function:
- Number of units is the same as number of classes
- $a_j$ is the probability that prediction is $j$, because we are using the exponential, a small change in $z_1$ leads to a much bigger change in $a_1$
- Comparing to other activation functions, a unit is not independent, it's depending on other units

Implementation with TensorFlow

```python
model = Sequential(
  [
    Dense(25, activation = 'relu'),
    Dense(15, activation = 'relu'),
    Dense(4, activation = 'linear')   #<-- use linear here
  ]
)
model.compile(
  loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),  #<-- This informs the loss function that the softmax operation should be included in the loss calculation. This allows for an optimized implementation.
  optimizer=tf.keras.optimizers.Adam(0.001),
)

model.fit(
  X_train,y_train,
  epochs=10
)

prediction = model.predict(X_test)  # prediction, value not contained in 0 to 1
prediction_p = tf.nn.softmax(prediction) # apply Softmax, value ranges from 0 to 1
```

- You can use `softmax` as the output layer, but it is more numerically stable if we pass `linear` output to the loss function during training.
- `Adam` stands for "Adaptive Moment" estimation
  - You specify an initial learning rate $\alpha$
  - It makes $\alpha$ bigger or smaller to make convergence faster
  - It uses different $\alpha$ values for each parameter

### Convolutional layer

![Convolutional layer](images/ml_neural-network-convolutional-layer.png)

We usually use `Dense` layer type, which means each neuron/unit in a layer is using all values of the input

There are other layer types, such as "convolutional", where each unit only looks at part of the values.

- Each neuron can look at different number of values, eg. one neuron takes 5 input values, another takes 4
- A value can be used by multiple neurons
- This layer type may perform better in some cases

### Bias and variance

- High bias: increase the network size
  - A large NN can usually fit well to the traning data
- High variance: get more data

![Bias and variance](images/ml_bias-and-variance.png)

- $J_{cv}$ is usually larger than $J_{train}$
- With polynomial regression models, when you increase the degree
  - $J_{train}$ usually goes down
  - $J_{cv}$ usually goes down, then up


## Model validation

It is common to split your data into three parts:

- **training set** - used to train the model
- **cross validation set** (also called validation, development, or dev set) - used to tune other model parameters like degree of polynomial, regularization or the architecture of a neural network
- **test set** - used to give a fair estimate of your chosen model's performance on new examples. This **should not** be used to make decisions while you are still developing the models

Generally you choose the model with the least error on cross validation set

### Technics

- **Error analysis**: manually examine a sample of the training examples that the model misclassified in order to identify common traits and trends
- **Data augmentation**: take an existing training example and modify it (for example, by rotating an image slightly) to create a new example with the same label
  ![Data augmenttation](images/ml_data-augmentation.png)
- Transfer learning:
  - Two problems of same input type(eg. images, audio, text), you have a large dataset for problem1, a small one for problem2
  - **Pretaining**: train a model for problem1
  - **Fine tuning**: use the parameters as initial parameters for problem2
  - For the model for problem2, you can
    - train parameters of all layers
    - or only train output layer parameters, keep other parmaters untouched
  - You often can download parameters of large models and use it for your data


## Decision tree

Two decisions to make

- Which feature to use in each node
  - Use entropy function to measure the impurity of children nodes
- When to stop splitting
  - Reached 100% purity
  - Reached max depth of the tree
  - Reached min number of samples
  - Information gain from additional splits is below threshold

### Entropy function

Used to measure impurity

![Entropy function](./images/ml_decision-tree-entropy.png)

- max impurity (1) when it's a 50/50 split
- max purity (0) when it's a 100/0 split

![Information gain](images/ml_decision-tree-information-gain.png)

We choose a feature to maximize information gain (entropy reduction), which is the entropy value at current node minus weighted entropy on children nodes

$$\text{Information Gain} = H(p_1^\text{node})- \left(w^{\text{left}}H\left(p_1^\text{left}\right) + w^{\text{right}}H\left(p_1^\text{right}\right)\right),$$

and $H$ is the entropy, defined as

$$H(p_1) = -p_1 \text{log}_2(p_1) - (1- p_1) \text{log}_2(1- p_1)$$

### Regression tree

![Information gain for regression tree](images/ml_decision-tree-regression.png)

If the target is a continuous value instead of a class, we calculate information gain based on **variance reduction**, instead of entropy reduction, this kind of tree is called **regression tree**

### Tree ensembles

A single decision tree is not so robust, a minor change in the sample may change the final tree a lot.

To make it work better, we use these two ways:
- Instead of a single tree, we build multiple trees (aka Tree ensemble). If you have $m$ examples in the training set, for each tree, you sample the training set $m$ times (with replacement), so the new set size is still $m$ (some of them might be duplicates because of sampling with replacement).
- **Random forest**, if the dataset has $n$ features, we randomly choose $k$ feature for each tree, usually $k = \sqrt{n}$

### XGBoost

Instead of sampling each of the $m$ samples equally, it gives higher weight to mis-classified samples in previous trees.


## Skewed dataset

For skewed dataset, eg. for rare diseases, there's only a very small number of positive examples, the usual accuracy metric is not so useful.

We usually use **precision** and **recall** to measure the effectiveness of the model:

![Precision and recall](images/ml_precision-recall.png)

You often need to make a tradeoff between precision and recall

![Tradeoff between precision and recall](images/ml_precision-recall-tradeoff.png)

You usually need to make the decision yourself on the threshold.

Alternatively, you could use the $F_1$ score:

![F1 score](images/ml_f1-score.png)

  $$F_1 = \frac{1}{\frac{1}{2}(\frac{1}{P} + \frac{1}{R})} = \frac{2\cdot P \cdot R}{P + R}$$

$F_1$ score is also called *Harmonic mean*, which emphasizes the smaller value


## References

[Machine Learning | Coursera](https://www.coursera.org/specializations/machine-learning-introductIon)