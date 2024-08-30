# OpenShift


## Overview


## Authorization

![OpenShift RBAC](./images/openshift_rbac.png)

```sh
# get all Cluster Role Bindings
oc get clusterrolebindings

# show all roles in a project
oc get rolebindings

# show definition of a rolebinding
oc describe rolebinding <rolebinding-name>
oc describe clusterrolebinding <rolebinding-name>

# describe a role
oc describe role <role-name>
oc describe clusterrole <role-name>
```

Define a rolebinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  annotations:
    ...
  name: <name>
  namespace: <project-name>
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: <role-name>
subjects:
- kind: ServiceAccount
  name: <sa-name>
  namespace: <project-name>
```


## CLI

```sh
# login
oc login --token=<token> --server=<server>

# get all projects
oc get projects

# switch context to a project
oc project <project-name>
```
