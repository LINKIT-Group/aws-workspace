FROM python:3.8-slim-buster

RUN mkdir /build
COPY requirements.in build/

RUN apt-get update --fix-missing \
    && apt-get -y install --no-install-recommends \
        bash \
        jq \
        curl \
        git \
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
    && cd /build \
    && pip-compile requirements.in \
    && pip install -r requirements.txt

# keep cdk excluded from pipenv until its stable
RUN python -m pip install \
        aws-cdk.core \
    && npm install -g aws-cdk


ARG HOST_UID=${HOST_UID:-0}
ARG HOST_USER=${HOST_USER:-root}
ARG USER_HOME=${USER_HOME:-/root}

COPY files/cfn-Makefile "${USER_HOME}"/
COPY files/aliases "${USER_HOME}"/.aliases
COPY files/profile /etc/
COPY files/*.sh /etc/profile.d/

RUN sh -c "[ \"${HOST_USER}\" = root ]" || \
    (groupadd -r ${HOST_USER} -g ${HOST_UID} \
    && useradd -d "${USER_HOME}" -M -r -l -N -s /usr/sbin/nologin \
       -u ${HOST_UID} -g ${HOST_UID} ${HOST_USER} \
    && mkdir -p "${USER_HOME}" \
    && chown -R "${HOST_UID}:${HOST_UID}" "${USER_HOME}")

WORKDIR /repo
