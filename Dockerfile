FROM registry.cern.ch/docker.io/cern/alma9-base:latest

WORKDIR /root

COPY install.sh /root

RUN bash /root/install.sh && rm -f /root/install.sh /root/anaconda-ks.cfg /root/original-ks.cfg

CMD ["tail", "-f", "/dev/null"]
