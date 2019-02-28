FROM ubuntu:bionic

# These commands run as root 
# Install base dependencies
RUN apt-get update && \ 
    apt install -y \
        build-essential \
        libmagic-dev \ 
        libopenblas-dev \
        libx11-6 \
        libx11-dev \
        locales \
        sudo \
        unzip \
        wget

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV HOME /home/newuser

# Create new user, setup password, provide sudo rights
RUN useradd -ms /bin/bash newuser && \
    echo 'newuser:newpass' | chpasswd && \
    adduser newuser sudo

# Create a new user to run the pipeline
USER newuser
WORKDIR /home/newuser

# Commands below run as newuser
COPY --chown=newuser:newuser payload/scorer.zip ./ 
COPY --chown=newuser:newuser payload/license.sig .driverlessai/

# install Miniconda
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p $HOME/miniconda3 && \
    echo 'export PATH=$HOME/miniconda3/bin:$PATH' >> .bashrc && \
    unzip scorer.zip 

WORKDIR scoring-pipeline

RUN export PATH="$HOME/miniconda3/bin:$PATH" && \
    bash run_example.sh --pm conda