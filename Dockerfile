FROM quay.io/luet/base:latest
ADD https://raw.githubusercontent.com/mocaccinoOS/os-commons/master/packages/mocaccino/mocaccino-skel/luet.yaml /etc/luet/luet.yaml
ADD https://raw.githubusercontent.com/mocaccinoOS/repository-index/master/packages/mocaccino-desktop.yml /etc/luet/repos.conf.d/mocaccino-desktop.yml
ADD https://raw.githubusercontent.com/mocaccinoOS/repository-index/master/packages/mocaccino-repository-index.yml /etc/luet/repos.conf.d/mocaccino-repository-index.yml

ENV USER=root

SHELL ["/usr/bin/luet", "install", "-y", "-d"]
RUN repository/mocaccino-repository-index

RUN repository/luet
RUN repository/mocaccino-desktop
RUN repository/mocaccino-os-commons
RUN layers/system-x

SHELL ["/bin/sh", "-c"]
RUN rm -rf /var/cache/luet/packages/ /var/cache/luet/repos/
RUN luet cleanup

ENV TMPDIR=/tmp
ENTRYPOINT ["/bin/sh"]
