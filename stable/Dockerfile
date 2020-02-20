FROM python:3.8-slim-buster

COPY files/generated/requirements.txt .

RUN apt-get update --fix-missing \
    && apt-get -y install --no-install-recommends \
        bash \
        procps \
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

COPY files/etc/* /etc/
COPY files/profile.d/*.sh /etc/profile.d/
COPY files/generated/scripts /scripts
COPY files/generated/cfn-Makefile /
COPY files/aliases /.aliases
COPY files/entrypoint.sh /

WORKDIR /git
CMD ["/bin/sh", "/entrypoint.sh" ]
