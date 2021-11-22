# EKS

## Overview

- EKS communication between control and worker nodes:
  ![EKS architecture](images/eks-architecture.svg)

- EKS high level overview:
  ![EKS](images/eks-high-level.svg)

  - Worker nodes are replicated across multiple AZs

## `eksctl`

Create an EKS cluster with a single command:

```sh
clusterName=gary-test-cluster

eksctl create cluster \
  --name ${clusterName} \
  --region ap-southeast-2 \
  --nodegroup-name linux-nodes \
  --node-type t2.micro \
  --nodes 2

# IAM Users and Roles are bound to an EKS Kubernetes cluster via a ConfigMap named aws-auth.
# the following line creates the identity mapping, adding your role as admin within the cluster
eksctl create iamidentitymapping \
  --cluster ${clusterName} \
  --arn ${rolearn} \
  --group system:masters \
  --username admin

# show user mappings
kubectl describe configmap -n kube-system aws-auth
```

## RBAC

- Namespaces are security boundaries, intended to be used in multi-tenant environments to create virtual clusters
- There are two types of Roles
  - Role, RoleBinding: within a namespace
  - ClusterRole, ClusterRoleBinding: cluster-wide

Example: provide limited access to pods running in the `rbac-test` namespace for a user named `rbac-user`

- Create namespace and a deployment

  ```sh
  kubectl create namespace rbac-test
  # deploy nginx to it
  kubectl create deploy nginx --image=nginx -n rbac-test

  # get all in the namespace
  kubectl get all -n rbac-test
  ```

- Creates IAM user

  ```sh
  # create IAM user and get access key
  aws iam create-user --user-name rbac-user
  aws iam create-access-key --user-name rbac-user | tee /tmp/create_output.json

  # Create a script to switch to the new RBAC user
  cat << EoF > rbacuser_creds.sh
  export AWS_SECRET_ACCESS_KEY=$(jq -r .AccessKey.SecretAccessKey /tmp/create_output.json)
  export AWS_ACCESS_KEY_ID=$(jq -r .AccessKey.AccessKeyId /tmp/create_output.json)
  EoF
  ```

- Map an IAM user to a K8s user

  ```sh
  kubectl get configmap -n kube-system aws-auth -o yaml \
    | grep -v "creationTimestamp\|resourceVersion\|selfLink\|uid" \
    | sed '/^  annotations:/,+2 d' > aws-auth.yaml

  cat << EoF >> aws-auth.yaml
  data:
    mapUsers: |
      - userarn: arn:aws:iam::${ACCOUNT_ID}:user/rbac-user
        username: rbac-user
  EoF

  kubectl apply -f aws-auth.yaml
  ```

- Create role and role binding

  ```sh
  cat << EoF > rbacuser-role.yaml
  kind: Role
  apiVersion: rbac.authorization.k8s.io/v1
  metadata:
    namespace: rbac-test
    name: pod-reader
  rules:
  - apiGroups: [""] # "" indicates the core API group
    resources: ["pods"]
    verbs: ["list","get","watch"]
  - apiGroups: ["extensions","apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch"]
  EoF

  cat << EoF > rbacuser-role-binding.yaml
  kind: RoleBinding
  apiVersion: rbac.authorization.k8s.io/v1
  metadata:
    name: read-pods
    namespace: rbac-test
  subjects:
  - kind: User
    name: rbac-user
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    kind: Role
    name: pod-reader
    apiGroup: rbac.authorization.k8s.io
  EoF

  kubectl apply -f rbacuser-role.yaml
  kubectl apply -f rbacuser-role-binding.yaml
  ```

- Switch to new user

  ```sh
  . rbacuser_creds.sh

  # verify that user is switched
  aws sts get-caller-identity
  ```

- Verify

  ```sh
  # works
  kubectl get pods -n rbac-test

  # fails
  kubectl get pods -n kube-system
  ```