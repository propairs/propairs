FROM ubuntu:16.04
 
  
#propairs dependencies
RUN apt-get update && apt-get install -y \ 
   bsdmainutils \
   make \
   parallel \
   rsync \
   wget \
   zip

# postgres
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
   postgresql \
   postgresql-contrib \
   libpq-dev \
   sudo \
   netcat-traditional

# biopython dependencies
RUN apt-get update && apt-get install -y \
   build-essential \
   python2.7 \
   python2.7-dev \
   python2.7-numpy

# xtal dependencies
RUN apt-get update && apt-get install -y \
   g++-4.9 && \
   update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 20

# web-data dependencies
RUN apt-get update && apt-get install -y \ 
    imagemagick \
    pymol 


# setup propairs programm
COPY . /opt/propairs
RUN cd /opt/propairs && make -j 5
ENV PROPAIRSROOT /opt/propairs/
# used by parallel
ENV SHELL /bin/bash

# path where to write dataset and temp files
VOLUME ["/data/"]


# create propairs data set    
ENTRYPOINT ["/opt/propairs/dockerentry.sh"]

