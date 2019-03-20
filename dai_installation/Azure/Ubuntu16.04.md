Install H2O Driverless AI on base Ubuntu 16.04 on Azure
=======================================================

Create base Ubuntu 16.04 LTS Server
-----------------------------------

- **Select OS** - Login to Azure console and create a new compute instance. Select Ubuntu Server provided by Canonical. Select Ubuntu version as 16.04 LTS and [Deployment Method][1] as Resource Manager.
- **Select Azure VM Size** - Provide the necessary details like VM Name, Regions etc. as shown in in the image below. The most important selection here is the Instance Size. For this exercise I selected the least costly instance with a GPU card NC6 as seen in the image below. Consider the proper [Azure instance sizing recommendation][4] based on your use case.
- **Configure authentication** - Configure the authentication settings either using password of public-private key pair.
- **Configure Storage** - For this setup, I installed DAI on the same disk where the OS is installed.
  - By default, Azure VMs are configured with OS disk size of 30GB approx. This is not sufficient for DAI.
  - To increase the OS disk size, once the VM is running you will need to stop it.
  - Once stopped, resize the OS disk partition to at-least 500GB and then restart the server.
  - **For real use cases** it is strongly recommended to not persist any application information on the OS drive, but to [attach a data disk to the Azure VM][5] and to use this data drive for persisting DAI information. Premium SSD are recommended.
- **Configure Networking** - Configure networking as needed. At a minimum, ensure that your compute instance would have a public IP. Configure the Network Security Group to allow incoming connections to port 22 and 12345. DAI using 12345 and you will need to ssh to the server.
- Accept defaults for Monitoring and Management options
- **Guest Configs** - Azure provides capability to install Nvidia drivers and CUDA libraries as a guest extension. For DAI, I decided to install Nvidia drivers and CUDA manually to ensure that everything is compatible

> H2O Driverless AI uses Tensorflow 1.11 built against CUDA 9.0. Per [Nvidia Compatibility Matrix][6], Nvidia driver version 384.XX is the minimum one needed and was the default when CUDA 9.0 was shipped. We recommend this driver version as we have tested against it. However, not that if your GPU hardware is Turing based then 384.xx will not work. In that case, go to 396.XX. I have heard of some issues with driver 410 with CUDA 9.0, but am unaware of the specifics.

Install Nvidia 384.xx driver
----------------------------

- Once the server is up, ssh to it. You will be in your home directory
- Run the following commands to get it up to date
  - `sudo apt-get update`
  - `sudo apt-get upgrade`
- Navigate to [Nvidia CUDA download archive][7], and select `Linux` > `x86_64` > `Ubuntu` > `16.04` > `deb (network)`. Copy the link to the `cuda-repo-ubuntu1604_9.0.176-1_amd64.deb` file.
- Install the downloaded package `sudo dpkg -i cuda-repo-ubuntu1604_9.0.176-1_amd64.deb`
- Add the apt key `sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub`
- `sudo apt-get update`
- At this point, we will proceed to install `nvidia-384` driver as compared to the default that would get selected per `apt policy`. To do that issue the command `sudo apt install nvidia-384*`Let the driver installation complete. 
- At this point, the drivers would not to lodaded into the kernel. `lsmod | grep nvidia` should not return anything

At this point you will need to restart the compute instance from Azure console for the drivers to be loaded.

The below gif captures the commands I tried the installation process

![Install Nvidia driver](images/01_nvidia_driver_install.gif)

Install CUDA 9.0 toolkit
------------------------

- SSH to the machine once it restarts and verify that nvidia drivers are loaded `lsmod | grep nvidia`. This time it should list the nvidia kernel modules loaded in the kernel.
- Issue the command `nvidia-smi` and it should show details about your GPU card. This verifies your driver is installed properly and we proceed to install CUDA libraries.
- We install CUDA using [CUDA Meta-packages][8] instead of installing the complete cuda package. To install needed meta-packages issue command `sudo apt install cuda-toolkit-9-0 cuda-libraries-9-0 cuda-libraries-dev-9-0`
- The above step would install CUDA libraries in `/usr/local/cuda` directory, where `cuda` is a soft link to the currently used CUDA version. This means that one can install more than one CUDA versions on the same machine.
- We update `$PATH` to include the CUDA `bin` directory. Issue the command `export PATH=/usr/local/cuda/bin:$PATH`  
- To validate CUDA installation we will install CUDA sample code in `$HOME` directory, compile a CUDA program and test if it works. In the below steps we compile the `deviceQuery` sample and execute it. If it displays details about the CUDA interface and GPU details then we have successfully installed CUDA library

```shell
cd $HOME
cuda-install-samples-9.0.sh .
cd NVIDIA_Sam*
cd 1_Utilities/deviceQuery
make
./deviceQuery
```

Install cuDNN
-------------

- To install cuDNN issue the below commands

```shell
cd $HOME
wget https://s3-us-west-2.amazonaws.com/h2o-internal-release/libcudnn7_7.3.1.20-1%2Bcuda9.0_amd64.deb
wget https://s3-us-west-2.amazonaws.com/h2o-internal-release/libcudnn7-doc_7.3.1.20-1%2Bcuda9.0_amd64.deb
wget https://s3-us-west-2.amazonaws.com/h2o-internal-release/libcudnn7-dev_7.3.1.20-1%2Bcuda9.0_amd64.deb

sudo dpkg -i libcudnn7_7.3.1.20-1+cuda9.0_amd64.deb
sudo dpkg -i libcudnn7-dev*.deb
sudo dpkg -i libcudnn7-doc*.deb
```

The below gif captures the commands I tried the installation process

Install Docker CE
-----------------

- Update the system `sudo apt-get update`
- Install needed packages `sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common`
- Add docker GPG key `curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -`
- Verify fingerprint is of docker `sudo apt-key fingerprint 0EBFCD88`
- Add repository

```shell
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
```

- Update the packages again `sudo apt update`
- Install docker `sudo apt-get install docker-ce docker-ce-cli containerd.io`
- To execute docker commands the user needs to be part of the `docker` group. To add the user to the `docker` group issue the command `usermod -aG docker $USER`
- Exit your shell and reconnect. 
- Issue the command `id`, and verify the user is part of `docker` group.
- To verify all is ok issue the command `docker run --rm hello-world`. It will pull a docker image from the docker hub and finally display a `Hello World` message 

[Docker installation reference][9]

Install nvidia-docker2
----------------------

- To install nvidia-docker2, we need to get the repository added to the apt list [Reference][10]

```shell
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
```

- Next, install nvidia-docker2 using the command `sudo apt install nvidia-docker2`
- Restart the docker daemon using the command `sudo pkill -SIGHUP dockerd`
- To validate, execute the command `nvidia-docker2 run --rm nvidia/cuda nvidia-smi` and this should give you desired output.

[nvidia-docker2 install reference][11]

Set Nvidia Persistance mode
---------------------------
- Driverless AI requires the persistance mode to enabled on each GPU that would be used with DAI
- We recommend setting up [Nvidia Persistance daemon][12] to manage the persistance mode setting on each GPU you have on your machine.
- To manually enable persistance mode on all GPUs issue the command `sudo nvidia-smi -pm 1`
- To validate, issue the command `nvidia-smi` and verify that persistance mode setting is turned ON.
- Also validate the setting is visible within the nvidia-docker using the command `nvidia-docker2 run --rm nvidia/cuda nvidia-smi`

At this point your system setup tasks are pretty much completed and you can start with [installing Driverless AI][13] following the directions step 5 onwards.

You can [download latest Driverless AI][14] docker image from [https://www.h2o.ai/download/#driverless-ai][14]

[1]: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-deployment-model
[2]: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/n-series-driver-setup
[3]: https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/hpccompute-gpu-linux
[4]: http://docs.h2o.ai/driverless-ai/latest-stable/docs/userguide/install/azure.html#environment
[5]: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal
[6]: https://docs.nvidia.com/deploy/cuda-compatibility/index.html#binary-compatibility__table-toolkit-driver
[7]: https://developer.nvidia.com/cuda-90-download-archive
[8]: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#package-manager-metas
[9]: https://docs.docker.com/install/linux/docker-ce/ubuntu/
[10]: https://nvidia.github.io/nvidia-docker/
[11]: https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0)#installing-version-20
[12]: https://docs.nvidia.com/deploy/driver-persistence/index.html#usage
[13]: http://docs.h2o.ai/driverless-ai/latest-stable/docs/userguide/install/ubuntu.html
[14]: https://www.h2o.ai/download/#driverless-ai














