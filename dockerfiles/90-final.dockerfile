FROM rtluckie/seedy:brew-go-latest AS seedy-brew-go
FROM rtluckie/seedy:brew-pyenv-latest AS seedy-brew-pyenv
FROM rtluckie/seedy:brew-brewfiles-latest AS seedy-brew-brewfiles
FROM rtluckie/seedy:base-latest AS seedy-base
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
    LANG=en_US.UTF-8

ARG DEBIAN_FRONTEND=noninteractive

COPY files/etc/profile.d /etc/profile.d
COPY files/lib/systemd/system/ /lib/systemd/system/
COPY files/usr/local/bin/ /usr/local/bin/

COPY --from=seedy-brew-go --chown=1000:100 /go/bin /go/bin
COPY --from=seedy-brew-brewfiles --chown=1000:100 /home/linuxbrew/.linuxbrew /home/linuxbrew/.linuxbrew
COPY --from=seedy-brew-brewfiles --chown=1000:100 /home/linuxbrew/bundles/* /home/linuxbrew/bundles/
COPY --from=seedy-brew-pyenv --chown=1000:100 /root/.pyenv /root/.pyenv

RUN localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    /usr/local/bin/seedy-configure

RUN apt -qqy update && apt -qqy upgrade && \
    apt-get -qqy clean && apt-get -qqy autoremove && rm -rf /var/lib/apt/lists/*

EXPOSE 2022
CMD ["/lib/systemd/systemd"]
