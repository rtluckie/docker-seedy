FROM ubuntu:focal AS phase01
ARG DEBIAN_FRONTEND=noninteractive

RUN yes | unminimize && \
    apt-get -qqy update && \
    apt-get -qqy install --no-install-recommends \
        software-properties-common && \
    apt-get -qqy install --no-install-recommends \
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

FROM linuxbrew/brew:3.1.3 as linuxbrew
USER root
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h
USER linuxbrew
ENV HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    LANG=en_US.UTF-8 \
    SHELL=/usr/bin/bash \
    PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH
COPY files/home/linuxbrew/bundles/10-base.brew /home/linuxbrew/bundles/
RUN brew bundle --no-upgrade install --no-lock --file \
        /home/linuxbrew/bundles/10-base.brew
USER root
RUN brew cleanup \
    && rm -fr /home/linuxbrew/.cache

# ------------------

# FROM linuxbrew/brew:3.1.3 AS gobin
# ENV LANG=en_US.UTF-8 \
# 	SHELL=/usr/bin/bash \
#     PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
#     GOPATH=/go
# RUN brew install go gcc && \
# 	ln -s $(brew --prefix gcc)/bin/gcc /usr/local/bin/gcc-5
# RUN eval $($(brew --prefix)/bin/brew shellenv) && \
#     (cd /tmp; GO111MODULE=on go get github.com/davidrjenni/reftools/cmd/fillstruct@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/fatih/gomodifytags@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/fatih/motion@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/go-delve/delve/cmd/dlv@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/golangci/golangci-lint/cmd/golangci-lint@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/josharian/impl@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.3.0) && \
#     (cd /tmp; GO111MODULE=on go get github.com/jstemmer/gotags@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/kisielk/errcheck@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/klauspost/asmfmt/cmd/asmfmt@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/koron/iferr@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/mitchellh/gox) && \
#     (cd /tmp; GO111MODULE=on go get github.com/rogpeppe/godef@master) && \
#     (cd /tmp; GO111MODULE=on go get github.com/vmware/govmomi/govc) && \
#     (cd /tmp; GO111MODULE=on go get golang.org/x/lint/golint@master) && \
#     (cd /tmp; GO111MODULE=on go get golang.org/x/tools/cmd/goimports@master) && \
#     (cd /tmp; GO111MODULE=on go get golang.org/x/tools/cmd/gorename@master) && \
#     (cd /tmp; GO111MODULE=on go get golang.org/x/tools/cmd/guru@master) && \
#     (cd /tmp; GO111MODULE=on go get golang.org/x/tools/gopls@latest) && \
#     (cd /tmp; GO111MODULE=on go get honnef.co/go/tools/cmd/keyify@master)
# ------------------

FROM phase01 AS final
ENV LANG=en_US.UTF-8 \
	PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash

RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# COPY --from=gobin --chown=1000:100 /go/bin /go/bin
COPY --from=linuxbrew --chown=1000:100 /home/linuxbrew/.linuxbrew /home/linuxbrew/.linuxbrew
COPY files/etc/profile.d /etc/profile.d
COPY files/lib/systemd/system/ /lib/systemd/system/
COPY files/usr/local/bin/ /usr/local/bin/
COPY --chown=1000:100 files/home/linuxbrew/bundles/* /home/linuxbrew/bundles/

RUN /usr/local/bin/seedy-configure

RUN for BREW in $(ls /home/linuxbrew/bundles | grep -v base | grep '.brew' ); do \
        brew bundle install --no-lock --file /home/linuxbrew/bundles/${BREW}; \
    done

EXPOSE 2022
CMD ["/lib/systemd/systemd"]
