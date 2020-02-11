# --------------------------------------------------------------------
# Copyright (c) 2019 Anthony Potappel - LINKIT, The Netherlands.
# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------

SERVICE_TARGET ?= $(strip $(if $(target),$(target),stable))
WORKDIR := ~/repositories

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
export WORKDIR


.PHONY: shell
shell:
ifeq ($(CMD_ARGUMENTS),)
	@# no command is given, default to shell
	@[ -d $(WORKDIR) ] || mkdir $(WORKDIR)
	docker-compose run --rm $(SERVICE_TARGET) bash -l
else
	@# run the command
	@[ -d $(WORKDIR) ] || mkdir $(WORKDIR)
	docker-compose run --rm $(SERVICE_TARGET) bash -l -c "$(CMD_ARGUMENTS)"
endif

.PHONY: build
build:
	docker-compose build $(SERVICE_TARGET)

.PHONY: whoami
whoami:
	@[ -d $(WORKDIR) ] || mkdir $(WORKDIR)
	docker-compose run --rm $(SERVICE_TARGET) bash -l -c "whoami"
	
.PHONY: clean
clean:
	@echo 'Nothing to cleanup'
