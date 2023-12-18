# Anomaly detection

- [Algorithm](#algorithm)
- [Selecting threshhold $\\varepsilon$](#selecting-threshhold-varepsilon)
- [Anomaly detection vs. Supervised learning](#anomaly-detection-vs-supervised-learning)


## Algorithm

To perform anomaly detection, you will first need to fit a model to the data’s distribution.

- Given a training set $\{x^{(1)}, ..., x^{(m)}\}$, you want to estimate the Gaussian distribution for each
of the features $x_i$.

- Recall that the Gaussian distribution (aka. normal distribution) is given by

   $$ p(x ; \mu,\sigma ^2) = \frac{1}{\sqrt{2 \pi \sigma ^2}}\exp^{ - \frac{(x - \mu)^2}{2 \sigma ^2} }$$

   where $\mu$ is the mean and $\sigma^2$ is the variance.

- For each feature $i = 1\ldots n$, you need to find parameters $\mu_i$ and $\sigma_i^2$ that fit the data in the $i$-th dimension $\{x_i^{(1)}, ..., x_i^{(m)}\}$ (the $i$-th dimension of each example).

- You can estimate the parameters, ($\mu_i$, $\sigma_i^2$), of the $i$-th
feature by using the following equations. To estimate the mean, you will
use:

  $$\mu_i = \frac{1}{m} \sum_{j=1}^m x_i^{(j)}$$

  and for the variance you will use:

  $$\sigma_i^2 = \frac{1}{m} \sum_{j=1}^m (x_i^{(j)} - \mu_i)^2$$


## Selecting threshhold $\varepsilon$

Now that you have estimated the Gaussian parameters, you can investigate which examples have a very high probability given this distribution and which examples have a very low probability.

  - The low probability examples are more likely to be the anomalies in our dataset.
  - One way to determine which examples are anomalies is to select a threshold based on a cross validation set.

We can select the best threshold $\varepsilon$ based on the $F_1$ score on a cross validation set.

- We will use a cross validation set
$\{(x_{\rm cv}^{(1)}, y_{\rm cv}^{(1)}),\ldots, (x_{\rm cv}^{(m_{\rm cv})}, y_{\rm cv}^{(m_{\rm cv})})\}$, where the label $y=1$ corresponds to an anomalous example, and $y=0$ corresponds to a normal example.
- For each cross validation example, we will compute $p(x_{\rm cv}^{(i)})$.

To find the best (maximum value of) $F_1$:

- We try many different values of $\varepsilon$ (1000 steps from the minimun and maximum values of $p(x_{\rm cv}^{(i)})$) and select the best $\varepsilon$ based on the $F_1$ score.

- Recall that if an example $x$ has a low probability $p(x) < \varepsilon$, then it is classified as an anomaly.

- Then, you can compute precision and recall by:

   $$\begin{aligned}
   prec&=&\frac{tp}{tp+fp}\\
   rec&=&\frac{tp}{tp+fn},
   \end{aligned}$$

   where

    - $tp$ is the number of true positives: the ground truth label says it’s an anomaly and our algorithm correctly classified it as an anomaly.
    - $fp$ is the number of false positives: the ground truth label says it’s not an anomaly, but our algorithm incorrectly classified it as an anomaly.
    - $fn$ is the number of false negatives: the ground truth label says it’s an anomaly, but our algorithm incorrectly classified it as not being anomalous.

  - The $F_1$ score is computed using precision ($prec$) and recall ($rec$) as follows:
    $$F_1 = \frac{2\cdot prec \cdot rec}{prec + rec}$$

An example:

![Example](images/ml_anomaly-detection-example.png)

*Gaussian contours of data set with two features, the red ellipse represents $\varepsilon$, red circled points are anomalies*


## Anomaly detection vs. Supervised learning

- Use Anomaly detection if:
  - Very small number (0-20 is common) of positive examples ($y = 1$), and large number of negative ($y=0$) examples
  - Many different "types" of anomalies. Hard for any algorithm to learn from positive examples what the anomalies look like; future anomalies may look nothing like any of the anomalous examples we've seen so far
  - Typical usecases:
    - Fraud detection
    - Manufacturing - Finding new, previously unseen defects in manufacturing
    - Monitoring machines

- Use Supervised learning if:
  - Large number of positive and negative examples
  - Enough positive examples for algorithm to get a sense of what positive examples are like, future positive examples likely to be similar to ones in training set
  - Typical usecases:
    - Email spam classification
    - Manufacturing - Finding known, previously seen defects
    - Weather prediction
    - Diseases classification