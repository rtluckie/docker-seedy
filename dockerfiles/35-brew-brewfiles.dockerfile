ARG BREW_IMAGE='linuxbrew/brew:3.1.6'

FROM $BREW_IMAGE
USER root
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h
USER linuxbrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1

RUN brew update && brew upgrade

COPY --chown=1000:100 files/home/linuxbrew/bundles/* /home/linuxbrew/bundles/

RUN for BREW in $(ls /home/linuxbrew/bundles | grep '.brew' ); do \
      brew bundle install --no-lock --file /home/linuxbrew/bundles/${BREW}; \
    done && \
    brew cleanup && \
    rm -fr /home/linuxbrew/.cache
