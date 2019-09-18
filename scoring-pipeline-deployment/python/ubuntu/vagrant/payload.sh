#!/usr/bin/env bash

wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda3
echo 'export PATH=$HOME/miniconda3/bin:$PATH' >> ~/.bashrc
export PATH=$HOME/miniconda3/bin:$PATH
unzip scorer.zip && cd scoring-pipeline
bash run_example.sh --pm conda