H2O.ai Driverless AI installation from scratch
==============================================

This directory lists guides to manually setup [H2O.ai Driverless AI][1] on baremetal machines and various clouds.

While the guides mention a cloud provider (which is where I tried the steps), they are not specific to the cloud provider and should work on other clouds like AWS, GCP, and even on a bare-metal machine.

**[Azure/Ubuntu16.04.md](Azure/Ubuntu16.04.md)**

- Guide to setup Driverless AI from scratch on Ubuntu 16.04 LTS.
- We install the following things in order
  - Nvidia Drivers
  - CUDA 9.0
  - docker-ce
  - nvidia-docker and then configure the GPU cards for user is H2O Driverless AI
- We explain the process using a VM on Azure, but then setup steps should be valid for baremetal as well as VMs in other clouds.


[1]: https://www.h2o.ai/products/h2o-driverless-ai/