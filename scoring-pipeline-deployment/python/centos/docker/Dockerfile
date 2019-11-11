FROM centos:centos7

# These commands run as root
# Install base dependencies
RUN yum -y update && \
    yum install -y epel-release && \
    yum -y groupinstall 'Development Tools' && \
    yum install -y openblas-devel openblas python36-virtualenv python36-pip wget unzip java && \
    ln -s /usr/bin/virtualenv-3.6 /usr/bin/virtualenv && \
    ln -s /usr/bin/pip-3.6 /usr/bin/pip && \
    ln -sf /usr/bin/python3 /usr/bin/python

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV HOME /home/newuser

# Create new user
RUN useradd -ms /bin/bash newuser

# Create a new user to run the pipeline
USER newuser
WORKDIR /home/newuser

# Commands below run as newuser
COPY --chown=newuser:newuser payload/scorer.zip ./
COPY --chown=newuser:newuser payload/license.sig .driverlessai/

RUN unzip scorer.zip

WORKDIR scoring-pipeline

RUN bash run_example.sh
