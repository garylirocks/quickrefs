# Clustering

- [Algorithm](#algorithm)
- [Initialize](#initialize)


## Algorithm

![K-means algorithm](images/ml_clustering-k-means-algorithm.png)

``` python
# Initialize centroids
# K is the number of clusters
centroids = kMeans_init_centroids(X, K)

for iter in range(iterations):
  # Cluster assignment step:
  # Assign each data point to the closest centroid.
  # idx[i] corresponds to the index of the centroid
  # assigned to example i
  idx = find_closest_centroids(X, centroids)

  # Move centroid step:
  # Compute means based on centroid assignments
  centroids = compute_centroids(X, idx, K)
```

- In cluster assignment step:

  For every example $x^{(i)}$ we set

  $$c^{(i)} := j \quad \mathrm{that \; minimizes} \quad ||x^{(i)} - \mu_j||^2,$$

  where
  - $c^{(i)}$ is the index of the centroid that is closest to $x^{(i)}$ (corresponds to `idx[i]` in the starter code), and
  - $\mu_j$ is the position (value) of the $j$’th centroid. (stored in `centroids` in the starter code)
  - $||x^{(i)} - \mu_j||$ is the L2-norm (aka. Euclidean distance) - square root of the sum of the squared vector values

- In the move centroid step:

  For every centroid $\mu_k$ we set
  $$\mu_k = \frac{1}{|C_k|} \sum_{i \in C_k} x^{(i)}$$

  where

  - $C_k$ is the set of examples that are assigned to centroid $k$
  - $|C_k|$ is the number of examples in the set $C_k$

  Concretely, if two examples say $x^{(3)}$ and $x^{(5)}$ are assigned to centroid $k=2$,
  then you should update $\mu_2 = \frac{1}{2}(x^{(3)}+x^{(5)})$.


Cost function: //TODO


## Initialize

- Choose $K < m$
  - $K$ is usually ambiguous, it might be not only a technical decision, could be a business decision as well
- Randoming pick $K$ training examples as $\mu_1 ... \mu_k$
- You should run this multiple times (usually between 50 ~ 1000), and choose one with lowest cost $J$