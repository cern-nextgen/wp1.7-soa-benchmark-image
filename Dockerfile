FROM registry.cern.ch/docker.io/cern/alma9-base:latest

WORKDIR /root

COPY install.sh /root

RUN bash /root/install.sh

CMD ["tail", "-f", "/dev/null"]
