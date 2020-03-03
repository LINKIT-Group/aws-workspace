FROM python:3.8-slim-buster

COPY generated/requirements.txt .

RUN apt-get update --fix-missing \
    && apt-get -y install --no-install-recommends \
        bash \
        procps \
        openssh-client \
        jq \
        curl \
        git \
        make \
        gosu \
        zip \
        unzip \
    && python -m pip install \
        pip-tools==4.4.1 \
        virtualenv==20.0.4 \
    && pip install -r requirements.txt

COPY generated/etc/* /etc/
COPY generated/profile.d/*.sh /etc/profile.d/
COPY generated/scripts /scripts
COPY generated/cfn-Makefile /
COPY generated/aliases /.aliases
COPY generated/entrypoint.sh /

WORKDIR /git
CMD ["/bin/sh", "/entrypoint.sh" ]
