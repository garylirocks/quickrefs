# Recommender systems

- [Implementation](#implementation)

## Collaborative filtering

You generated two vectors, a user vector (uer preference for features) and an item/movie vector (movie features) whose dot product would predict a rating.


## TensorFlow custom training loop

![TensorFlow auto diff](images/ml_tensorflow-auto-diff.png)

*TensorFlow can calculate differentiation, use `tf.Variable` to create the parameter you want to optimize*


## Content-based filtering

While Collaborative filtering uses **only ratings** data, Content-based filtering

- Takes into account other information available about the user and/or movie that may improve the prediction.
- The additional information is provided to a neural network which then generates the user and movie vector as shown below.

![Content](images/ml_recommender-system-content-based-filtering.png)
