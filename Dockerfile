FROM ubuntu:14.04

# biopython
RUN apt-get update && apt-get install -y \
   python2.7 python2.7-dev python2.7-numpy
RUN apt-get install -y \
   rsync \
   wget 
RUN cd /root/ && wget http://biopython.org/DIST/biopython-1.65.tar.gz && \
  tar xzvf biopython-1.65.tar.gz && \
  cd biopython-1.65 && \
  python2.7 setup.py build && \
  python2.7 setup.py install
  
# postgres
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
   postgresql-9.3 \
   postgresql-contrib-9.3 \
   postgresql-9.3-postgis-2.1 \
   libpq-dev \
   sudo \
   netcat-traditional
RUN echo "local all  postgres  peer " >  /etc/postgresql/9.3/main/pg_hba.conf && \
   echo "local all  all       trust" >> /etc/postgresql/9.3/main/pg_hba.conf && \
   /etc/init.d/postgresql start && \
   sudo -u postgres createuser -s ppiuser && \
   sudo -u postgres createdb -O ppiuser ppidb1

# install propairs/xtal
COPY . /imagefiles
RUN apt-get install -y bsdmainutils r-base

ENV PROPAIRSROOT /imagefiles/propairs/

VOLUME ["/data/"]

ENTRYPOINT ["/imagefiles/start.sh"]

