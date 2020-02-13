FROM python:3.8-slim-buster

COPY requirements.txt .

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
    && pip install -r requirements.txt

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
