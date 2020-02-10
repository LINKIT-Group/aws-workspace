# --------------------------------------------------------------------
# Copyright (c) 2019 Anthony Potappel - LINKIT, The Netherlands.
# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------

SERVICE_TARGET ?= $(strip $(if $(target),$(target),stable))
REPO_DIRECTORY = ~/repositories

ifeq ($(user),)
# USER retrieved from env, UID from shell.
HOST_USER ?= $(strip $(if $(USER),$(USER),root))
HOST_UID ?= $(strip $(if $(shell id -u),$(shell id -u),0))
else
# allow override by adding user= and/ or uid=  (lowercase!).
# uid= defaults to 0 if user= set (i.e. root).
HOST_USER = $(user)
HOST_UID = $(strip $(if $(uid),$(uid),0))
endif

ifeq ($(HOST_USER),root)
USER_HOME = /root
else
USER_HOME = /home/$(HOST_USER)
endif

CMD_ARGUMENTS ?= $(cmd)

# export such that its passed to shell functions for Docker to pick up.
export HOST_USER
export HOST_UID
export USER_HOME
export REPO_DIRECTORY


.PHONY: shell
shell:
ifeq ($(CMD_ARGUMENTS),)
	@# no command is given, default to shell
	@[ -d $(REPO_DIRECTORY) ] || mkdir $(REPO_DIRECTORY)
	docker-compose run --rm $(SERVICE_TARGET) bash -l
else
	@# run the command
	@[ -d $(REPO_DIRECTORY) ] || mkdir $(REPO_DIRECTORY)
	docker-compose run --rm $(SERVICE_TARGET) bash -l -c "$(CMD_ARGUMENTS)"
endif

.PHONY: build
build:
	docker-compose build $(SERVICE_TARGET)

.PHONY: whoami
whoami:
	@[ -d ~/local ] || mkdir ~/local
	docker-compose run --rm $(SERVICE_TARGET) bash -l -c "whoami"
	
.PHONY: clean
clean:
	@[ -d ~/local ] || mkdir ~/local
	docker-compose run --rm $(SERVICE_TARGET) bash -l -c "make clean"
