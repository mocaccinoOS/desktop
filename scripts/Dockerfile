FROM alpine

RUN apk add curl bash sed grep
RUN curl https://luet.io/install.sh | sh 

ENV LUET_YES=true
ENV LUET_NOLOCK=true
RUN luet install repository/mocaccino-extra
RUN luet install -qy utils/jq utils/yq

ENTRYPOINT /bin/bash