ARG CUDA
ARG CUDNN
ARG KERAS
ARG TF
ARG USER
ARG USERID

# FROM ubuntu:18.04
FROM nvcr.io/nvidia/cuda:${CUDA}-base-ubuntu18.04

ARG CUDA
ARG CUDNN
ARG KERAS
ARG TF
ARG USER
ARG USERID

# -qq, no output except errors
# https://askubuntu.com/questions/258219/how-do-i-make-apt-install-less-noisy
ARG APT_ARGS="-qq -o=Dpkg::Use-Pty=0"
ARG CLEAN_CMD="apt-get -qq -o=Dpkg::Use-Pty=0 autoclean" 

# Should be together, always, because of layer catching
RUN apt-get ${APT_ARGS} update && apt-get ${APT_ARGS} -y upgrade && ${CLEAN_CMD}

RUN apt-get update && apt-get install -y --no-install-recommends \
  libcudnn7=$CUDNN-1+cuda${CUDA} && \
  apt-mark hold libcudnn7 && \
  rm -rf /var/lib/apt/lists/*

ARG DEBIAN_FRONTEND=noninteractive

# Python 3.6

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

RUN apt-get ${APT_ARGS} update && \
    if [ "$CUDA" != "10.0" ]; then \
      apt-get ${APT_ARGS} install -y libcublas10; \
    else \
      cudVersion="$(echo ${CUDA} | tr . -)"; \
      apt-get ${APT_ARGS} install -y cuda-cublas-$cudVersion; \
    fi

RUN cudVersion="$(echo ${CUDA} | tr . -)"; \
    apt-get ${APT_ARGS} install -y --no-install-recommends \
        build-essential \
	    vim \
	    nano \
        git \
        wget \
        ssh \
	    cuda-command-line-tools-$cudVersion \
        cuda-cufft-$cudVersion \
        cuda-curand-$cudVersion \
        cuda-cusolver-$cudVersion \
        cuda-cusparse-$cudVersion \
        locales \
        python3.6 \
        python3-pip \
        python3-setuptools \
        python3.6-dev \
        pkg-config\
        curl\
        docker.io

RUN python3 -m pip --quiet install --upgrade --user pip

# Sudo, Vim, Git, tree
RUN apt-get ${APT_ARGS} install -y sudo tree && ${CLEAN_CMD}

# Python Libraries - NOT Includes TensorFlow and Keras
COPY ./requirements.txt /tmp/requirements.txt
RUN python3 -m pip --quiet install -r /tmp/requirements.txt

# Link python to python3
RUN rm /usr/bin/python; \
    ln -s /usr/bin/python3.6 /usr/bin/python

# TensorFlow

# If TF major version >= 2, need updated setuptools
RUN if [ "$(echo $TF | head -c 1)" = "2" ]; then \
        python3 -m pip install --upgrade pip; \
        python3 -m pip install --upgrade setuptools; \
    fi

RUN python3 -m pip --quiet install tensorflow-gpu==${TF}

# We only install Keras if TF version is lesser than 2
RUN if [ "$(echo $TF | head -c 1)" = "1" ]; then \
        # Keras
        python3 -m pip --quiet install keras==${KERAS}; \
    fi

# User
RUN useradd -m -s /bin/bash ${USER} -u ${USERID} -G sudo -p $(openssl passwd -1 docker); \
    usermod -aG sudo ${USER}
USER ${USER}

# Bash configuration to both root and regular user
COPY ./Config/.bashrc /home/${USER}/
COPY ./Config/.bash_aliases /home/${USER}/
COPY ./Config/.bashrc /root/
COPY ./Config/.bash_aliases /root/

# Copy ssh config and hosts
COPY ./Config/config /home/${USER}/.ssh/
COPY ./Config/config /root/.ssh/

COPY ./Config/hosts /etc/hosts

# What does start when docker run this image
ENTRYPOINT [ "/bin/bash" ]