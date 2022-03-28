ARG base_image=ubuntu:20.04
FROM ${base_image}
LABEL maintainer="contact@cycloid.io" \
      initiator="kazuki suda <ksuda@zlab.co.jp>"

ARG KUBERNETES_VERSION=

# Do NOT update the next line manually, please use ./scripts/update-aws-iam-authenticator.sh instead
ARG AWS_IAM_AUTHENTICATOR_VERSION=v0.5.3

RUN set -x && \
    apt-get update && \
    apt-get install -y jq curl python3-minimal && \
    # Download and install kubectl
    [ -z "$KUBERNETES_VERSION" ] && KUBERNETES_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) ||: && \
    curl -s -LO https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    kubectl version --client && \
    # Download and install aws-iam-authenticator
    curl -s -L -o /usr/local/bin/aws-iam-authenticator "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/${AWS_IAM_AUTHENTICATOR_VERSION}/aws-iam-authenticator_$(echo "$AWS_IAM_AUTHENTICATOR_VERSION" | tr -d v)_linux_amd64" && \
    chmod +x /usr/local/bin/aws-iam-authenticator && \
    aws-iam-authenticator version && \
    # Download and install gcloud
    curl -sSL https://sdk.cloud.google.com > ./install.sh && \
    bash install.sh --disable-prompts --install-dir=/opt && \
    ln -s /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud && \
    gcloud --version && \
    rm -rf /var/lib/apt/lists/* ./install.sh

RUN mkdir -p /opt/resource
COPY assets/* /opt/resource/
