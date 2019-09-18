#!/usr/bin/env bash

yum -y update 
yum -y groupinstall 'Development Tools'
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install openblas-devel openblas python36-virtualenv python36-pip 

# create links
ln -s /usr/bin/virtualenv-3.6 /usr/bin/virtualenv
ln -s /usr/bin/pip-3.6 /usr/bin/pip
ln -sf /usr/bin/python3 /usr/bin/python
