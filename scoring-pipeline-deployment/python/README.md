Python Scoring Pipeline Deployment Examples
===========================================

Driverless AI scoring pipelines can be deployed independently of the machine
where Driverless AI is running. This essentially helps you to separate the 
concerns of Model Training from Model Deployment. This capability gives you
immense flexibility on how you can deploy your scoring pipelines to production.

This directory lists example code that shows how to deploy Python Scoring Pipeline
in various scenarios

Bare-metal or Virtual Linux Environments
----------------------------------------

The `vagrant` directory contains example code that explains how to get DAI 
python scoring pipeline installed and running on a Ubuntu 18.04 linux. The example
uses Ubuntu 10.04 running on Virtualbox managed via Vagrant. The example can be
used the understand the steps needed to get the scoring pipeline working, which
can be adjusted per your scenarios.


Containerised Environments
--------------------------

The `docker` directory contains example code to show how to create a Ubuntu 18.04
based container that can be used to deploy the python scoring pipeline.


