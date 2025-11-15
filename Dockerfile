ARG base_image=debian:stable-slim
FROM ${base_image}
LABEL maintainer="contact@cycloid.io" \
      initiator="kazuki suda <ksuda@zlab.co.jp>"

ARG KUBERNETES_VERSION=
ARG GCLOUD_INSTALL=true

# Do NOT update the next line manually, please use ./scripts/update-aws-iam-authenticator.sh instead
# https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/
ARG AWS_IAM_AUTHENTICATOR_VERSION=v0.7.9

# https://docs.cloud.google.com/sdk/docs/release-notes
ARG CLOUD_SDK_VERSION=547.0.0
# ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION

RUN set -x && \
    apt-get update && \
    apt-get install -y jq curl python3-minimal gnupg && \
    # Download and install kubectl
    [ -z "$KUBERNETES_VERSION" ] && KUBERNETES_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt) ||: && \
    curl -s -LO https://dl.k8s.io/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl && \

    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    kubectl version --client && \
    # Download and install aws-iam-authenticator
    curl -s -L -o /usr/local/bin/aws-iam-authenticator "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/${AWS_IAM_AUTHENTICATOR_VERSION}/aws-iam-authenticator_$(echo "$AWS_IAM_AUTHENTICATOR_VERSION" | tr -d v)_linux_amd64" && \
    chmod +x /usr/local/bin/aws-iam-authenticator && \
    aws-iam-authenticator version

# https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/master/Dockerfile
RUN if [ "$GCLOUD_INSTALL" = "true" ] ; then \
    apt-get update && apt-get install -y curl gnupg lsb-release ; \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"; \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/google-cloud.gpg] http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/google-cloud.gpg && \
    apt-get update && \
    apt-get install -y google-cloud-cli=${CLOUD_SDK_VERSION}-0 \
    google-cloud-cli-gke-gcloud-auth-plugin=${CLOUD_SDK_VERSION}-0 ; \
    gcloud config set core/disable_usage_reporting true ; \
    gcloud config set component_manager/disable_update_check true ; \
    gcloud config set metrics/environment github_docker_image ; \
    gcloud --version ; \
    fi

# cleanup
RUN apt-get autoremove --purge -y curl && \
    apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN mkdir -p /opt/resource
COPY assets/* /opt/resource/