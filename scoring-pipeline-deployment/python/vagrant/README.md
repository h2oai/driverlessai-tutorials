Python Scoring Pipeline Wrapper using Vagrant
=============================================

This directory contains sample code that explains the steps needed to deploy a python scoring pipeline
obtained from H2O Driverless AI in a Ubuntu 18.04 virtual machine in Vagrant.


Prerequisites
-------------

The following pre-requisites are needed
- [VirtualBox](https://www.virtualbox.org/): A free virtualization provider
- [Vagrant](https://www.vagrantup.com/): A tool for building and managing virtual machines
- [Vagrant Disk Resize plugin](https://github.com/sprotheroe/vagrant-disksize): A vagrnt plugin to manage disk sizes

Follow the installation instructions for your platform and get them installed in the above order.


Code Structure
--------------

The code assumes a directory structure as below:

```
top-dir: A directory with the below structure. Name of directory can be anything.
- README.md: This file with the details you are reading
- Vagrantfile: File providing the definition of the virtual machine to create using Vagrant
- bootstrap.sh: The shell provisioner, installs core ubuntu packages
- payload.sh: Shell provisioner, installs Miniconda, creates scoring environment, runs pipeline  
- payload: A directory that contains files which can be used in the virtual machine for deployment
    - scorer.zip: The DAI python scoring pipeline. (You need to put this file here)
    - license.sig: Valid Driverless AI license file. (You need to provide your license file here)
```

Instructions
------------

1. Install VirtualBox
2. Install Vagrant. Ensure you can invoke it using `vagrant --version`
2. Install Vagrant Disk Size plugin `vagrant plugin install vagrant-disksize`
3. Go to `top-dir`, which contains the files as mentioned in the above section
4. Copy the scoring pipeline `scorer.zip` in the `payload` directory. You may need to create the `payload` directory.
5. Copy Driverless AI license `license.sig` in the `payload` directory
6. Issue the command `vagrant up`. This will
    - Create a Ubuntu 18.04 based virtual machine
    - Bootstrap it i.e. install all dependencies, miniconda, python etc..
    - Create a conda environment for the scoring pipeline by installing all needed dependencies
    - Run `example.py` from the scoring pipeline

You can SSH to the machine using the command `vagrant ssh` from `top-dir` directory. Once connected it is like
working on any Ubuntu terminal.

To run `example.py` you can follow the below steps once you are connected using SSH

```
conda env list                            # shows conda environments available on the system
conda activate environment_name           # activate environment for required experiment (experiment key is in name)
python example.py                         # to run example.py manually
```

Similarly, you can run the HTTP and TCP server python files too.

Multiple Deployments on same Host
---------------------------------

Each DAI experiment python deployment pipeline should be contained in its own virtual python environment.
We support both `conda` and `pip + virtualenv` based virtual environments. This separation enables flexibility
to have multiple experiment scoring pipelines to be deployed on the same machine without interfering with
each other.


Disclaimer
----------

The scoring pipeline wrapper code shared in this directory is created to provide you 
a sample starting point and is not intended to be directly deployed to production as is.
You can use this starting point and build over it to solve your deployment needs ensuring
that your security etc. requirements are met.
