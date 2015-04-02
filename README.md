# ProPairs

ProPairs identifies protein docking complexes using biological assembly information with corresponding unbound structures from the Protein Data Bank (PDB). The bound and unbound protein structures can be used as benchmark sets to develop or to test algorithms that predict protein docking geometries. 

## Quick Start

Get the source code of ProPairs from the GitHub repository:
  ```
  git clone --recursive https://github.com/f-krull/propairs
  ```

We chose Docker to make ProPairs easy to use - regardless of the configuration of your system.
Build the ProPairs Docker container:
  ```
  cd propairs
  docker build -t propairs .
  ```

Create a directory to store the output data (If you choose a different directory, make sure to reuse it in the next steps!):
  ```
  mkdir ~/ppdata
  ```

Run ProPairs on a test set (takes a few minutes):
  ```
  docker run --rm -v ~/ppdata:/data propairs -t 1
  ```

This will generate raw data files with the suffix "3_clustered" for the large ProPairs set and the suffix "4_merged" for the non-redundant ProPairs set. After the step above, these files will be relatively small, since only a subset of the PDB was considered. You can run the ProPairs program on the complete PDB archive (will take days!) with:
  ```
  docker run --rm -v ~/ppdata:/data propairs -t 0
  ```

### Requirements

* X86-64 machine with Git and Docker installed (see below for other architectures)
* At least 4GB RAM per core
* ~200GB of free disk space
* Internet connection

### Ubuntu

On Ubuntu 14.04 you can install Git and Docker like this:
  ```
  sudo apt-get install git docker.io
  sudo adduser $USER docker
  ```

## Without Docker

You can compile the ProPairs C++ code without Docker on different architectures (it even runs on a Raspberry Pi). The Dockerfile will give you an idea how to set up your system. Be sure to have the PostgreSQL DBMS configured and running.

Once the dependencies are installed get the source code and run "make":
  ```
  git clone --recursive https://github.com/f-krull/propairs
  cd propairs
  make
  ```
Depending on the architecture the Makefiles might need fixes (GitHub pull requests are very welcome!!).

Start the ProPairs program like this:
  ```
  mkdir ~/ppdata
  ./start.sh -i `pwd` -o ~/ppdata -t 1
  ```
