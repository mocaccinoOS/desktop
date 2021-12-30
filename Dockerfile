FROM quay.io/luet/base:latest
ADD https://raw.githubusercontent.com/mocaccinoOS/os-commons/master/packages/mocaccino/mocaccino-skel/luet.yaml /etc/luet/luet.yaml
ADD https://raw.githubusercontent.com/mocaccinoOS/repository-index/master/packages/mocaccino-desktop.yml /etc/luet/repos.conf.d/mocaccino-desktop.yml

ENV USER=root

SHELL ["/usr/bin/luet", "install", "-y", "-d"]

RUN repository/luet
RUN repository/mocaccino-desktop
RUN repository/mocaccino-os-commons
RUN repository/mocaccino-repository-index
RUN layers/system-x

SHELL ["/bin/sh", "-c"]
RUN rm -rf /var/cache/luet/packages/ /var/cache/luet/repos/

ENV TMPDIR=/tmp
ENTRYPOINT ["/bin/sh"]