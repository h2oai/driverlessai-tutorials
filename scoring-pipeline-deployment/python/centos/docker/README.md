Python Scoring Pipeline Wrapper using Docker
============================================

This directory contains sample code that explains the steps needed to deploy a python scoring pipeline
obtained from H2O Driverless AI in a Ubuntu 18.04 docker container. This directory acts as the build 
context for the docker build step. 


Prerequisites
-------------

The following pre-requisites are needed
- [Docker](https://www.docker.com/) 

Follow the installation instructions for your platform and get Docker Ce (or EE) installed on the machine. 


Code Structure
--------------

The code assumes a directory structure as below:

```
top-dir: A directory with the below structure. Name can be anything. This is the build context for docker build command
- README.md: This file with the details you are reading
- Dockerfile: The docker image build script
- payload: A directory that contains files to be used in the docker container for deployment
    - scorer.zip: The DAI python scoring pipeline. (You need to put this file here)
    - license.sig: Valid Driverless AI license file. (You need to provide your license file here)
```

Instructions
------------

1. Install Docker. Ensure you can invoke it using `docker version`. It should display client and server version of docker
3. Change to `top-dir`, which contains the files as mentioned in the above section
4. Copy the scoring pipeline `scorer.zip` in the `payload` directory. You may need to create the `payload` directory.
5. Copy Driverless AI license `license.sig` in the `payload` directory
6. Issue the command `docker build -t scoretest .`. This will
    - Create a CentOS 7 based docker container 
    - Install required dependencies, python etc..
    - Create a virtual environment for the scoring pipeline by installing all needed dependencies
    - Run `example.py` from the scoring pipeline

As part of the build process you will see the scores being produced for the test data in `example.py`. This example
shows how to use DAI python scoring pipeline as a python module. There are other options like HTTP service and TCP service that can be created too.

You can run the docker container in interactive model, and can experiment with the HTTP and TCP endpoints.

Execute the command `docker run -it --rm scoretest:latest`. Once connected you will be in the `scoring-pipeline` directory.

To run `example.py` you can follow the below steps once you are connected using SSH

```
. env/bin/activate # activate environment for required experiment
python example.py  # to run example.py manually
```

Similarly, you can run the HTTP and TCP server python files too.


Disclaimer
----------

The scoring pipeline wrapper code shared in this directory is created to provide you 
a sample starting point and is not intended to be directly deployed to production as is.
You can use this starting point and build over it to solve your deployment needs ensuring
that your security etc. requirements are met.
