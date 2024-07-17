FROM python:3.12

RUN apt-get install -y wget
# RUN apt-get install -y iputils-ping net-tools

# https://github.com/kubernetes-sigs/kubespray/blob/v2.25.0/docs/ansible/ansible.md
ENV KUBESPRAY_VERSION=v2.25.0

WORKDIR /kubespray

RUN wget https://raw.githubusercontent.com/kubernetes-sigs/kubespray/${KUBESPRAY_VERSION}/requirements.txt
RUN pip install -r requirements.txt

RUN cat <<EOF > requirements.yml
collections:
- name: https://github.com/kubernetes-sigs/kubespray
  type: git
  version: ${KUBESPRAY_VERSION}
EOF
RUN ansible-galaxy install -r requirements.yml

WORKDIR /repo
