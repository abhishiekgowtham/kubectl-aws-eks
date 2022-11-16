#!/usr/bin/env bash

set -e

access_key_id="$1"
secret_access_key="$2"
role_arn="$3"
command="$4"

# Set aws credentials
aws configure set aws_access_key_id $access_key_id --profile github-actions
aws configure set aws_secret_access_key $secret_access_key --profile github-actions
aws configure set region us-east-1 --profile github-actions # region doesn't matter
aws configure set $role_arn --profile github-actions
aws configure set role_session_name ghactions --profile github-actions
aws configure set source_profile github-actions --profile github-actions
aws configure set duration_seconds 900 --profile github-actions

echo "aws configured list: $(aws configure list)"

# Extract the base64 encoded config data and write this to the KUBECONFIG
echo "$KUBE_CONFIG_DATA" | base64 -d >/tmp/config
export KUBECONFIG=/tmp/config

if [ -z ${KUBECTL_VERSION+x} ]; then
  echo "Using kubectl version: $(kubectl version --client --short)"
else
  echo "Pulling kubectl for version $KUBECTL_VERSION"
  rm /usr/bin/kubectl
  curl -sL -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/"$KUBECTL_VERSION"/bin/linux/amd64/kubectl &&
    chmod +x /usr/bin/kubectl
  echo "Using kubectl version: $(kubectl version --client --short)"
fi

if [ -z ${IAM_VERSION+x} ]; then
  echo "Using aws-iam-authenticator version: $(aws-iam-authenticator version)"
else
  echo "Pulling aws-iam-authenticator for version $IAM_VERSION"
  rm /usr/bin/aws-iam-authenticator
  curl -sL -o /usr/bin/aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v"$IAM_VERSION"/aws-iam-authenticator_"$IAM_VERSION"_linux_amd64 &&
    chmod +x /usr/bin/aws-iam-authenticator
  echo "Using aws-iam-authenticator version: $(aws-iam-authenticator version)"
fi

sh -c "kubectl $command"
