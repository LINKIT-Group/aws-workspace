# --------------------------------------------------------------------
# Copyright (c) 2019 Anthony Potappel - LINKIT, The Netherlands.
# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------

NAME := cloud-toolkit
SERVICE_TARGET ?= $(strip $(if $(target),$(target),stable))
WORKDIR := ~/repositories

ifeq ($(user),)
# USER retrieved from env, UID from shell.
HOST_USER ?= $(strip $(if $(USER),$(USER),root))
HOST_UID ?= $(strip $(if $(shell id -u),$(shell id -u),0))
HOST_GID ?= $(strip $(if $(shell id -u),$(shell id -g),0))
else
# allow override by adding user= and/ or uid=  (lowercase!).
# uid= defaults to 0 if user= set (i.e. root).
HOST_USER = $(user)
HOST_UID = $(strip $(if $(uid),$(uid),0))
endif

# export such that its passed to shell functions for Docker to pick up.
export HOST_USER
export HOST_UID
export HOST_GID
export WORKDIR


.PHONY: shell
shell:
	@# start new shell
	@[ -d $(WORKDIR) ] || mkdir $(WORKDIR)
	docker-compose -p $(NAME) run --rm $(SERVICE_TARGET)

.PHONY: build
build: 
	docker-compose -p $(NAME) build $(SERVICE_TARGET)

.PHONY: cfn-make
cfn-make:
	make -C devel/cfn-makefile
	printf "devel/files/generated/ stable/files/generated/" |xargs -n 1 cp -v devel/cfn-makefile/.build/cfn-Makefile

.PHONY: toolkit
toolkit: clean cfn-make
	# run development build to create input-artifacts in .build
	make build target=devel
	@# update build artifacts in .build
	@# - create temporary container from _devel target
	@$(eval tmp_container = $(shell \
		printf '$(NAME)_devel-'$$(($$(date +%s%N)/1000000)) \
	))
	docker create --name '$(tmp_container)' '$(NAME)_devel'
	@# - copy artifacts
	docker cp '$(tmp_container)':/build .build
	@# - cleanup temporary container
	docker rm '$(tmp_container)'
	# if update target == stable, copy build artifacts and call regular build
ifeq ($(SERVICE_TARGET),stable)
	# cp .build artifacts from devel to stable
	cp -rf .build/* stable/files/generated/
	make build
endif

.PHONY: whoami
whoami:
	@[ -d $(WORKDIR) ] || mkdir $(WORKDIR)
	docker-compose -p $(NAME) run --rm $(SERVICE_TARGET) bash -l -c "true"
	
.PHONY: clean
clean:
	[ ! -d .build ] || rm -rf .build
