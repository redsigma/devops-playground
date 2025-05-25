FROM debian:stable-slim AS control-node

RUN apt-get update && apt-get install -y --no-install-recommends pipx less ssh vim && pipx ensurepath

RUN pipx install ansible-core && pipx inject ansible-core pywinrm       && \
  mkdir -p /etc/ansible/                                                && \
  /bin/bash -c "source ~/.bashrc \
  && ansible-config init --disabled -t all > /etc/ansible/ansible.cfg \
  && mkdir -p /repo && chmod go-w /repo \
  && ansible-galaxy collection install ansible.windows community.windows"

#
# Install custom modules for windows defender
#
COPY ansible-win-defender/ /usr/share/ansible/plugins/modules/

WORKDIR /repo
