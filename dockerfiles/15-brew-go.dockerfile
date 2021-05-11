ARG BREW_IMAGE='linuxbrew/brew:${BREW_IMAGE_VERSION}'

FROM $BREW_IMAGE AS go
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    GOPATH=/go
RUN brew install go && \
    eval $($(brew --prefix)/bin/brew shellenv) && \
    (cd /tmp; GO111MODULE=on go get github.com/davidrjenni/reftools/cmd/...) && \
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
    (cd /tmp; GO111MODULE=on go get golang.org/x/tools/gopls) && \
    (cd /tmp; GO111MODULE=on go get honnef.co/go/tools/cmd/...)
