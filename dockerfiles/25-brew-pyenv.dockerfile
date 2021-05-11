ARG BREW_IMAGE='linuxbrew/brew:${BREW_IMAGE_VERSION}'

FROM $BREW_IMAGE AS go
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
RUN brew install pyenv
USER root
RUN eval $($(brew --prefix)/bin/brew shellenv) && \
    eval $(/usr/local/bin/brew_pyenv_setup.sh 2> /dev/null) && \
    pyenv install 3.7.10 && \
    pyenv install 3.8.9 && \
    pyenv install 3.9.4 && \
    find /root/.pyenv/versions -type d -name __pycache__ -exec rm -fr {} +
