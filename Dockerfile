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
    pyenv install 3.8.9 && \
    pyenv install 3.9.4 && \
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
    (cd /tmp; GO111MODULE=on go get github.com/davidrjenni/reftools/cmd/fillswitch) && \
    (cd /tmp; GO111MODULE=on go get github.com/davidrjenni/reftools/cmd/fixplurals) && \
    (cd /tmp; GO111MODULE=on go get github.com/davidrjenni/reftools/cmd/fillstruct) && \
    (cd /tmp; GO111MODULE=on go get github.com/fatih/gomodifytags) && \
    (cd /tmp; GO111MODULE=on go get github.com/fatih/motion) && \
    (cd /tmp; GO111MODULE=on go get github.com/go-delve/delve/cmd/dlv) && \
    (cd /tmp; GO111MODULE=on go get github.com/josharian/impl) && \
    (cd /tmp; GO111MODULE=on go get github.com/kisielk/errcheck) && \
    (cd /tmp; GO111MODULE=on go get github.com/klauspost/asmfmt/cmd/asmfmt) && \
    (cd /tmp; GO111MODULE=on go get github.com/koron/iferr) && \
    (cd /tmp; GO111MODULE=on go get github.com/mitchellh/gox) && \
    (cd /tmp; GO111MODULE=on go get github.com/rogpeppe/godef) && \
    (cd /tmp; GO111MODULE=on go get github.com/vmware/govmomi/govc) && \
    (cd /tmp; GO111MODULE=on go get golang.org/x/lint/golint) && \
    (cd /tmp; GO111MODULE=on go get golang.org/x/tools/...) && \
    (cd /tmp; GO111MODULE=on go get golang.org/x/tools/gopls@latest) && \
    (cd /tmp; GO111MODULE=on go get honnef.co/go/tools/cmd/...)

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
