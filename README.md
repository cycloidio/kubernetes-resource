# kubernetes-resource

[![Build Status](https://travis-ci.org/cycloid/kubernetes-resource.svg?branch=master)](https://travis-ci.org/cycloid/kubernetes-resource)

A Concourse resource for controlling the Kubernetes cluster.

*This resource supports AWS EKS. (kubernetes-sigs/aws-iam-authenticator@v0.5.3)*

## Versions

The version of this resource corresponds to the version of kubectl. We recommend using different version depending on the kubernetes version of the cluster.

 - `cycloid/kubernetes-resource:1.32` ([stable-1.32](https://storage.googleapis.com/kubernetes-release/release/stable-1.32.txt))
 - `cycloid/kubernetes-resource:1.31` ([stable-1.31](https://storage.googleapis.com/kubernetes-release/release/stable-1.31.txt))
 - `cycloid/kubernetes-resource:1.30` ([stable-1.30](https://storage.googleapis.com/kubernetes-release/release/stable-1.30.txt))
 - `cycloid/kubernetes-resource:1.29` ([stable-1.29](https://storage.googleapis.com/kubernetes-release/release/stable-1.29.txt))
 - `cycloid/kubernetes-resource:1.28` ([stable-1.28](https://storage.googleapis.com/kubernetes-release/release/stable-1.28.txt))
 - `cycloid/kubernetes-resource:1.27` ([stable-1.27](https://storage.googleapis.com/kubernetes-release/release/stable-1.27.txt))
 - `cycloid/kubernetes-resource:1.26` ([stable-1.26](https://storage.googleapis.com/kubernetes-release/release/stable-1.26.txt))
 - `cycloid/kubernetes-resource:1.25` ([stable-1.25](https://storage.googleapis.com/kubernetes-release/release/stable-1.25.txt))
 - `cycloid/kubernetes-resource:1.24` ([stable-1.24](https://storage.googleapis.com/kubernetes-release/release/stable-1.24.txt))
 - `cycloid/kubernetes-resource:1.23` ([stable-1.23](https://storage.googleapis.com/kubernetes-release/release/stable-1.23.txt))
 - `cycloid/kubernetes-resource:1.22` ([stable-1.22](https://storage.googleapis.com/kubernetes-release/release/stable-1.22.txt))
 - `cycloid/kubernetes-resource:1.21` ([stable-1.21](https://storage.googleapis.com/kubernetes-release/release/stable-1.21.txt))
 - `cycloid/kubernetes-resource:1.20` ([stable-1.20](https://storage.googleapis.com/kubernetes-release/release/stable-1.20.txt))
 - `cycloid/kubernetes-resource:latest` ([latest](https://storage.googleapis.com/kubernetes-release/release/latest.txt))

## Build Versions manually

```bash
# Available tags: https://hub.docker.com/repository/docker/cycloid/kubernetes-resource/tags?page=1&ordering=last_updated
VERSIONS="1.20 1.21 1.22 1.23 1.24 1.25 1.26 1.27 1.28 1.29 1.30 1.31 1.32"

LATEST=$(echo $VERSIONS| sed -E 's/.* ([^ ]+)$/\1/')
EXTRA_TAGS=""
for version in $VERSIONS;do
  KUBERNETES_VERSION=$(curl -q https://storage.googleapis.com/kubernetes-release/release/stable-$version.txt 2>/dev/null)
  echo $KUBERNETES_VERSION
  if [ "$version" = "$LATEST" ]; then
    EXTRA_TAGS="-t cycloid/kubernetes-resource:latest"
  fi
  docker build -t cycloid/kubernetes-resource:$version $EXTRA_TAGS . --build-arg KUBERNETES_VERSION=$KUBERNETES_VERSION
  docker push cycloid/kubernetes-resource:$version
  if [ "$version" = "$LATEST" ]; then
    docker push cycloid/kubernetes-resource:latest
  fi
done
```

## Source Configuration

### kubeconfig

- `kubeconfig`: *Optional.* A kubeconfig file.
    ```yaml
    kubeconfig: |
      apiVersion: v1
      clusters:
      - cluster:
        ...
    ```
- `context`: *Optional.* The context to use when specifying a `kubeconfig` or `kubeconfig_file`

### cluster configs

- `server`: *Optional.* The address and port of the API server.
- `token`: *Optional.* Bearer token for authentication to the API server.
- `namespace`: *Optional.* The namespace scope. Defaults to `default`. If set along with `kubeconfig`, `namespace` will override the namespace in the current-context
- `certificate_authority`: *Optional.* A certificate for the certificate authority.
    ```yaml
    certificate_authority: |
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
    ```
- `certificate_authority_file`: *Optional.* A file to read the certificate from. Only takes effect when `certificate_authority_file` is not set.
    ```yaml
    certificate_authority_file: ca_certs.crt
    ```
- `insecure_skip_tls_verify`: *Optional.* If true, the API server's certificate will not be checked for validity. This will make your HTTPS connections insecure. Defaults to `false`.
- `use_aws_iam_authenticator`: *Optional.* If true, the aws_iam_authenticator, required for connecting with EKS, is used. Requires `aws_eks_cluster_name`. Defaults to `false`.
- `aws_eks_cluster_name`: *Optional.* the AWS EKS cluster name, required when `use_aws_iam_authenticator` is true.
- `aws_eks_assume_role`: *Optional.* the AWS IAM role ARN to assume.
- `aws_access_key_id`: *Optional.* AWS access key to use for iam authenticator.
- `aws_secret_access_key`: *Optional.* AWS secret key to use for iam authenticator.
- `aws_session_token`: *Optional.* AWS session token (assumed role) to use for iam authenticator.

## Behavior

### `check`: Do nothing.

### `in`: Do nothing.

### `out`: Control the Kubernetes cluster.

Control the Kubernetes cluster like `kubectl apply`, `kubectl delete`, `kubectl label` and so on.

#### Parameters

- `kubectl`: *Required.* Specify the operation that you want to perform on one or more resources, for example `apply`, `delete`, `label`.
- `context`: *Optional.* The context to use when specifying a `kubeconfig` or `kubeconfig_file`
- `wait_until_ready`: *Optional.* The number of seconds that waits until all pods are ready. 0 means don't wait. Defaults to `30`.
- `wait_until_ready_interval`: *Optional.* The interval (sec) on which to check whether all pods are ready. Defaults to `3`.
- `wait_until_ready_selector`: *Optional.* [A label selector](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors) to identify a set of pods which to check whether those are ready. Defaults to every pods in the namespace.
- `kubeconfig_file`: *Optional.* The path of kubeconfig file. This param has priority over the `kubeconfig` of source configuration.
- `namespace`: *Optional.* The namespace scope. It will override the namespace in other params and source configuration.

## Example

```yaml
resource_types:
- name: kubernetes
  type: registry-image
  source:
    repository: cycloid/kubernetes-resource
    tag: "1.24"

resources:
- name: kubernetes-production
  type: kubernetes
  source:
    server: https://192.168.99.100:8443
    namespace: production
    token: {{kubernetes-production-token}}
    certificate_authority: {{kubernetes-production-cert}}
- name: my-app
  type: git
  source:
    ...

jobs:
- name: kubernetes-deploy-production
  plan:
  - get: my-app
    trigger: true
  - put: kubernetes-production
    params:
      kubectl: apply -f my-app/k8s -f my-app/k8s/production
      wait_until_ready_selector: app=myapp
```

### Force update deployment

```yaml
jobs:
- name: force-update-deployment
  serial: true
  plan:
  - put: mycluster
    params:
      kubectl: |
        patch deploy nginx -p '{"spec":{"template":{"metadata":{"labels":{"updated_at":"'$(date +%s)'"}}}}}'
      wait_until_ready_selector: run=nginx
```

### Use a remote kubeconfig file fetched by s3-resource

```yaml
resources:
- name: k8s-prod
  type: kubernetes

- name: kubeconfig-file
  type: s3
  source:
    bucket: mybucket
    versioned_file: config
    access_key_id: ((s3-access-key))
    secret_access_key: ((s3-secret))

- name: my-app
  type: git
  source:
    ...

jobs:
- name: k8s-deploy-prod
  plan:
  - aggregate:
    - get: my-app
      trigger: true
    - get: kubeconfig-file
  - put: k8s-prod
    params:
      kubectl: apply -f my-app/k8s -f my-app/k8s/production
      wait_until_ready_selector: app=myapp
      kubeconfig_file: kubeconfig-file/config
```

## License

This software is released under the MIT License.
