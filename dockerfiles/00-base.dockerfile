ARG BASE_IMAGE='ubuntu:focal'
FROM $BASE_IMAGE AS phase01

ARG DEBIAN_FRONTEND=noninteractive

RUN yes | unminimize && \
    apt -qqy update && apt -qqy upgrade && \
    apt -qqy install --no-install-recommends \
        software-properties-common && \
    apt -qqy install --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        dnsmasq \
        dnsutils \
        file \
        git \
        libcurl4-openssl-dev \
        locales \
        locate \
        man-db \
        ntp \
        ntpdate \
        openssh-server \
        sudo \
        systemd \
        systemd-sysv \
        tzdata \
        uuid-runtime \
        && \
   # DOCKER
    apt-get install -qqy --no-install-recommends \
        gnupg-agent \
    && \
    curl -sSfL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get -qqy update && \
    apt-get -qqy --no-install-recommends install \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        && \
# GOOGLE CLOUD SDK
    apt-get install -qqy --no-install-recommends \
        gnupg \
    && \
    curl -sSfL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    add-apt-repository "deb https://packages.cloud.google.com/apt cloud-sdk main" && \
    apt-get -qqy update && \
    apt-get -qqy --no-install-recommends install \
        google-cloud-sdk \
    && \
    apt-get -qqy clean && apt-get -qqy autoremove && rm -rf /var/lib/apt/lists/*

