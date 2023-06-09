# # [Choice] Ubuntu version (use jammy on local arm64/Apple Silicon): jammy, focal
# ARG VARIANT="jammy"
# FROM buildpack-deps:${VARIANT}-curl

# LABEL dev.containers.features="common"

# ARG USERNAME=aaron
# ARG USER_UID=1000
# ARG USER_GID=$USER_UID
# # Install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get install -y -qq --no-install-recommends fish \
#     && groupadd --gid $USER_GID $USERNAME \
#     && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
#     && apt-get update \
#     && apt-get install -y sudo \
#     && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
#     && chmod 0440 /etc/sudoers.d/$USERNAME \
#     && rm -rf /var/lib/apt/lists/* \
#     && dpkg-reconfigure -f noninteractive tzdata \
#     && date \
#     && apt-get autoclean

# USER $USERNAME
ARG VARIANT="jammy"
FROM --platform=linux/amd64 docker-registry-proxy.corp.amdocs.com/ubuntu:${VARIANT}
ARG USER_NAME=aaronla
ENV LOD_PLATFORM=docker
ENV DEBIAN_FRONTEND=noninteractive
RUN sh -c "$(/bin/echo -e 'cat << EOF | tee /etc/apt/apt.conf >/dev/null \
\nAcquire::http::Proxy "http://genproxy.corp.amdocs.com:8080";\
\nAcquire::https::Proxy "http://genproxy.corp.amdocs.com:8080";\
\nAcquire::https::Verify-Peer "false";\
\nEOF\n')" && \
# cp -p /etc/apt/sources.list /etc/apt/sources.list.$(date +'%Y%m%d%H%M%S') && \
# ln -sf /etc/apt/sources.list.amdocs /etc/apt/sources.list && \
apt-get update -y && \
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates wget curl sudo netcat virt-what iputils-ping openssh-client vim git && \
apt-get clean all && \
wget -q --no-check-certificate -O /usr/local/share/ca-certificates/FullAmdocsCA.crt https://gitlab.corp.amdocs.com/ansible-roles/setup-os-repositories-and-ca/-/blob/master/files/ca/FullAmdocsCA.crt && \
update-ca-certificates

RUN useradd --create-home --shell /usr/bin/bash ${USER_NAME} && \
usermod -a -G sudo ${USER_NAME} && \
echo "%${USER_NAME}   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME}

RUN export no_proxy=.amdocs.com,$no_proxy && \
curl -kSs https://gitlab.corp.amdocs.com/ansible-roles/image-template/raw/master/files/profile_proxy.sh >/tmp/proxy.sh && \
/bin/bash -c 'source /tmp/proxy.sh && proxy install' && \
sh -c "$(/bin/echo -e 'cat << EOF | tee -a /home/${USER_NAME}/.bashrc >/dev/null \
\nif [ -f "/etc/profile.d/profile_proxy.sh" ] ; then \
\n    source /etc/profile.d/profile_proxy.sh \
\nfi \
\nEOF\n')"

ENTRYPOINT ["/bin/bash", "-c"]
# CMD ["/entrypoint.sh"]

USER ${USER_NAME}:${USER_NAME}
WORKDIR /home/${USER_NAME}


# RUN export LOD_PLATFORM=docker && \
# wget -q --no-check-certificate -O - https://gitlab.corp.amdocs.com/SIGs/LinuxOnDesktop/raw/master/scripts.d/00-bootstrap.sh | bash

EXPOSE 3389 4389 22 8000 5000 80 443 8443 8080 8081 9090 8022
# 3389 xrdp
