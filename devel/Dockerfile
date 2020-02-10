FROM python:3.8-slim-buster

COPY Pipfile .

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
        pipenv==2018.11.26 \
    && pipenv install && pipenv install --system

# CDK is broken via pipenv
RUN python -m pip install \
        aws-cdk.core \
    && npm install -g aws-cdk

ARG HOST_UID=${HOST_UID:-0}
ARG HOST_USER=${HOST_USER:-root}
ARG USER_HOME=${USER_HOME:-/root}

COPY files/profile /etc/
COPY files/*.sh /etc/profile.d/

RUN sh -c "[ \"${HOST_USER}\" = root ]" || \
    (groupadd -r ${HOST_USER} -g ${HOST_UID} \
    && useradd -d "${USER_HOME}" -M -r -l -N -s /usr/sbin/nologin \
       -u ${HOST_UID} -g ${HOST_UID} ${HOST_USER} \
    && mkdir -p "${USER_HOME}" \
    && chown -R "${HOST_UID}:${HOST_UID}" "${USER_HOME}")

WORKDIR /repo
