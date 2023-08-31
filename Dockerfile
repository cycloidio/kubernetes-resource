ARG base_image=debian:bullseye-slim
FROM ${base_image}
LABEL maintainer="contact@cycloid.io" \
      initiator="kazuki suda <ksuda@zlab.co.jp>"

ARG KUBERNETES_VERSION=
ARG GCLOUD_INSTALL=true

# Do NOT update the next line manually, please use ./scripts/update-aws-iam-authenticator.sh instead
ARG AWS_IAM_AUTHENTICATOR_VERSION=v0.6.11

ENV OS=bullseye
ARG CLOUD_SDK_VERSION=444.0.0
# ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION

RUN set -x && \
    apt-get update && \
    apt-get install -y jq curl python3-minimal gnupg && \
    # Download and install kubectl
    [ -z "$KUBERNETES_VERSION" ] && KUBERNETES_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) ||: && \
    curl -s -LO https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    kubectl version --client && \
    # Download and install aws-iam-authenticator
    curl -s -L -o /usr/local/bin/aws-iam-authenticator "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/${AWS_IAM_AUTHENTICATOR_VERSION}/aws-iam-authenticator_$(echo "$AWS_IAM_AUTHENTICATOR_VERSION" | tr -d v)_linux_amd64" && \
    chmod +x /usr/local/bin/aws-iam-authenticator && \
    aws-iam-authenticator version
    # && \
    # Download and install gcloud
    # curl -sSL https://sdk.cloud.google.com > ./install.sh && \
    # bash install.sh --disable-prompts --install-dir=/opt && \
    # ln -s /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud && \
    # gcloud --version && \
    # rm ./install.sh

RUN if [ "$GCLOUD_INSTALL" = "true" ] ; then \
    export CLOUD_SDK_REPO="cloud-sdk-${OS}" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y google-cloud-cli=${CLOUD_SDK_VERSION}-0 \
        google-cloud-cli-gke-gcloud-auth-plugin=${CLOUD_SDK_VERSION}-0 && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version ; \
    fi

# cleanup
RUN apt-get autoremove --purge -y curl && \
    apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN mkdir -p /opt/resource
COPY assets/* /opt/resource/
