ARG BREW_IMAGE='linuxbrew/brew:${BREW_IMAGE_VERSION}'

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
