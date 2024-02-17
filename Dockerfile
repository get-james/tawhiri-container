# -------------------
# The build container
# -------------------
FROM debian:buster-slim AS build
#test9
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    unzip && \
  rm -rf /var/lib/apt/lists/*

ADD https://github.com/get-james/tawhiri/archive/master.zip /root/tawhiri-master.zip
RUN unzip /root/tawhiri-master.zip -d /root && \
  cd /root/tawhiri-master && \
  pip3 install --user --no-warn-script-location --ignore-installed -r requirements.txt && \
  python3 setup.py build_ext --inplace

# -------------------------
# The application container
# -------------------------
FROM debian:buster-slim

EXPOSE 8000/tcp

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    imagemagick \
    python3 \
    tini && \
  rm -rf /var/lib/apt/lists/*

COPY --from=build /root/.local /root/.local
COPY --from=build /root/tawhiri-master /root/tawhiri-master

RUN rm /etc/ImageMagick-6/policy.xml && \
  mkdir -p /run/tawhiri

WORKDIR /root

ENV PATH=/root/.local/bin:$PATH

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD /root/.local/bin/gunicorn -b 0.0.0.0:8000 -w 12 tawhiri.api:app
