ARG BASE_IMAGE='ubuntu:focal'
ARG BREW_IMAGE='linuxbrew/brew:3.1.5'

FROM $BASE_IMAGE AS phase01
ARG DEBIAN_FRONTEND=noninteractive

RUN yes | unminimize && \
    apt -qqy update && \
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
        zsh \
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

# ------------------

FROM $BREW_IMAGE as linuxbrew
USER root
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h
USER linuxbrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1
COPY --chown=1000:100 files/home/linuxbrew/bundles/* /home/linuxbrew/bundles/
COPY --chown=1000:100 files/usr/local/bin/* /usr/local/bin/

RUN brew update && brew upgrade && \
	for BREW in $(ls /home/linuxbrew/bundles | grep '.brew' ); do \
      brew bundle install --no-lock --file /home/linuxbrew/bundles/${BREW}; \
    done && \
    brew cleanup && \
    rm -fr /home/linuxbrew/.cache

USER root
RUN eval $($(brew --prefix)/bin/brew shellenv) && \
    eval $(/usr/local/bin/brew_pyenv_setup.sh 2> /dev/null) && \
    pyenv install 3.7.10 && \
    pyenv install 3.8.10 && \
    pyenv install 3.9.5 && \
    find /root/.pyenv/versions -type d -name __pycache__ -exec rm -fr {} +

# ------------------

FROM $BREW_IMAGE AS go
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    GOPATH=/go
RUN brew install go && \
    eval $($(brew --prefix)/bin/brew shellenv) && \
    PACKAGES=( \
    "github.com/davidrjenni/reftools/cmd/fillswitch" \ 
    "github.com/davidrjenni/reftools/cmd/fixplurals" \ 
    "github.com/davidrjenni/reftools/cmd/fillstruct" \ 
    "github.com/fatih/gomodifytags" \ 
    "github.com/fatih/motion" \ 
    "github.com/go-delve/delve/cmd/dlv" \ 
    "github.com/josharian/impl" \ 
    "github.com/kisielk/errcheck" \ 
    "github.com/klauspost/asmfmt/cmd/asmfmt" \ 
    "github.com/koron/iferr" \ 
    "github.com/mitchellh/gox" \ 
    "github.com/rogpeppe/godef" \ 
    "github.com/vmware/govmomi/govc" \ 
    "golang.org/x/lint/golint" \ 
    "golang.org/x/tools/..." \ 
    "golang.org/x/tools/gopls@latest" \ 
    "honnef.co/go/tools/cmd/..." \
    ) && \
    for package in "${PACKAGES[@]}"; do \
      (cd /tmp; GO111MODULE=on go get ${package}) \ 
    done

# ------------------

FROM phase01 AS final
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
    LANG=en_US.UTF-8

COPY --from=go --chown=1000:100 /go/bin /go/bin
COPY --from=linuxbrew --chown=1000:100 /home/linuxbrew/.linuxbrew /home/linuxbrew/.linuxbrew
COPY --from=linuxbrew --chown=1000:100 /root/.pyenv /root/.pyenv

COPY files/etc/profile.d /etc/profile.d
COPY files/lib/systemd/system/ /lib/systemd/system/
COPY files/usr/local/bin/ /usr/local/bin/
COPY --chown=1000:100 files/home/linuxbrew/bundles/* /home/linuxbrew/bundles/

RUN localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    /usr/local/bin/seedy-configure

EXPOSE 2022
CMD ["/lib/systemd/systemd"]
