FROM python:3.8-slim-buster

RUN mkdir -p /build/scripts \
    && ln -sf /build/scripts /scripts

COPY requirements.in build/

RUN apt-get update --fix-missing \
    && apt-get -y install --no-install-recommends \
        bash \
        procps \
        jq \
        curl \
        git \
        make \
        gosu \
        software-properties-common \
        build-essential \
        groff \
        zip \
        unzip \
    && curl -sL https://deb.nodesource.com/setup_10.x |bash - \
    && apt-get -y install --no-install-recommends \
        nodejs \
    && python -m pip install \
        pip-tools==4.4.1 \
        virtualenv==20.0.4 \
    && cd /build \
    && pip-compile requirements.in \
    && pip install -r requirements.txt

# keep cdk excluded from pipenv until its stable
RUN python -m pip install \
        aws-cdk.core \
    && npm install -g aws-cdk

COPY files/etc/* /etc/
COPY files/profile.d/*.sh /etc/profile.d/
COPY files/scripts/* /build/scripts/
COPY files/generated/cfn-Makefile /
COPY files/aliases /.aliases
COPY files/entrypoint.sh /

WORKDIR /git
CMD ["/bin/sh", "/entrypoint.sh" ]
