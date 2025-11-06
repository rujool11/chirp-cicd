#!/bin/bash

# stop any existing jenkins container
docker rm -f jenkins 2>/dev/null

# run jenkins
docker run -d \
  -u root \
  --name jenkins \
  --network host \
  -p 8081:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which docker):/usr/bin/docker \
  -v /home/$USER/.kube:/root/.kube \
  -v /home/$USER/.minikube:/root/.minikube \
  jenkins/jenkins:lts

# web ui (from -p 8001:8000)
# jenkins agent port
# persistent volume for jenkins data
# host docker socket so jenkins can access it 
# docker cli binary inside jenkins container
# jenkins can access local kubectl config
# mount minikube config and certs 

# wait for jenkins to be up
echo "waiting 10 seconds for jenkins container initialize..."
sleep 10

# install kubectl and minikube inside jenkins container
docker exec -u root jenkins bash -c "
  set -eux
  apt-get update -y
  apt-get install -y curl apt-transport-https gnupg lsb-release
  # install kubectl
  curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  # install minikube 
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  install minikube-linux-amd64 /usr/local/bin/minikube
  # verify installation
  kubectl version --client
  minikube version
"

# fix kubeconfig path mismatch inside container
echo "patching kubeconfig paths for container..."
docker exec -u root jenkins bash -c "
  if [ -f /root/.kube/config ]; then
    sed -i 's|/home/rujool|/root|g' /root/.kube/config
  fi
"

echo "Full jenkins setup ready"
