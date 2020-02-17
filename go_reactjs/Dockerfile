ARG OS
ARG ARCH
ARG VERSION
ARG USER
ARG USERID

FROM ubuntu:18.04

ARG OS
ARG ARCH
ARG VERSION
ARG USER
ARG USERID

# -qq, no output except errors
# https://askubuntu.com/questions/258219/how-do-i-make-apt-install-less-noisy
ARG APT_ARGS="-qq -o=Dpkg::Use-Pty=0"
ARG CLEAN_CMD="apt-get -qq -o=Dpkg::Use-Pty=0 autoclean" 

USER root

# Should be together, always, because of layer catching
RUN apt-get ${APT_ARGS} update && apt-get ${APT_ARGS} -y upgrade && ${CLEAN_CMD}

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG C.UTF-8

RUN apt-get ${APT_ARGS} install -y --no-install-recommends \
        build-essential \
	    vim \
	    nano \
        git \
        wget \
        ssh \
        locales \
        pkg-config \
        curl \
        docker.io \
        tar \
        sudo \
        tree \
        openssl \
        libssl1.0.0 \
        ca-certificates
        # ADD SUDO and...

# Certificates to trust Google
# https://serverfault.com/questions/314635/why-wget-doesnt-verify-ssl-certificates
RUN printf "\nca_directory=/etc/ssl/certs" | sudo tee -a /etc/wgetrc

# GO Installation
# https://golang.org/dl/
RUN wget -q https://dl.google.com/go/go${VERSION}.${OS}-${ARCH}.tar.gz; \
    tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz; \
    rm go$VERSION.$OS-$ARCH.tar.gz

# Regular user configuration
RUN useradd -m -s /bin/bash ${USER} -u ${USERID} -G sudo -p $(openssl passwd -1 docker); \
    usermod -aG sudo ${USER}

# Taking bashrc and bash_aliases if they're available
COPY ./.bash* home/${USER}/
COPY ./.bash* root/

# Adding go to PATH
RUN echo "\nexport PATH=$PATH:/usr/local/go/bin" >> /home/${USER}/.bashrc; \
    echo "\nexport PATH=$PATH:/usr/local/go/bin" >> /root/.bashrc

# Installing Mux and other Gorilla packages
RUN go get -u github.com/gorilla/mux; \
    go get -u github.com/gorilla/handlers

# Installing Node.js
# https://github.com/nodesource/distributions
RUN curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -; \
    apt-get ${APT_ARGS} install -y nodejs

# Installing react components
RUN npm i react-switch

# Entrypoint
USER ${USER}
ENTRYPOINT [ "/bin/bash" ]

# Build
# docker build -t fullstack --build-arg USER=$USER --build-arg USERID=$(id -u) --build-arg OS=linux --build-arg ARCH=amd64 --build-arg VERSION=1.13.7 .

# Run container
# docker run --mount src=/home/amartin/docker_dash/,target=/app,type=bind --network host --name FullStackInstance -di fullstack 

# Go inside it
# docker exec -it FullStackInstance /bin/bash