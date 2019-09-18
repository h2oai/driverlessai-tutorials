FROM ubuntu:bionic

# Similar to Dockerfile, but uses PIP to install dependencies without creating environment
# No user is created. Installs as root.
# Use as example code and modify as needed

# These commands run as root 
# Install base dependencies
RUN apt-get update && \ 
    apt install -y \
        build-essential \
        libmagic-dev \ 
        libopenblas-dev \
        git \
        locales \
	python3-pip \
        unzip \
        wget

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV HOME /root


WORKDIR $HOME

COPY payload/scorer.zip ./ 
COPY payload/license.sig .driverlessai/

RUN unzip scorer.zip 

WORKDIR scoring-pipeline

RUN python3 -m pip install --upgrade --upgrade-strategy only-if-needed pip==9.0.3 && \
    python3 -m pip install --upgrade --upgrade-strategy only-if-needed -r requirements.txt

