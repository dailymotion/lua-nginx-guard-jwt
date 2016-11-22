FROM openresty/openresty:xenial

MAINTAINER Stan Chollet <stanislas.chollet@dailymotion.com>

SHELL ["/bin/bash", "-c"]

RUN apt-get update
RUN apt-get install -y vim wget

RUN wget https://raw.githubusercontent.com/openresty/opm/master/bin/opm -O /usr/local/openresty/bin/opm
RUN chmod +x /usr/local/openresty/bin/opm
RUN echo 'export PATH="/usr/local/openresty/bin:$PATH"' >> /root/.bashrc

ENV PATH "/usr/local/openresty/bin:$PATH"

COPY ./lib /usr/local/openresty/site/lualib
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
