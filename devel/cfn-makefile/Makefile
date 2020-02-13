# --------------------------------------------------------------------
# Copyright (c) 2020 Anthony Potappel - LINKIT, The Netherlands.
# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------

CC = python3
ODIR = .build

TARGET = $(ODIR)/cfn-Makefile

OBJECTS := $(shell find src -name '*.cfn-template' -o -name '*.sh' -o -name '*.txt')

$(TARGET): $(OBJECTS) generate.py
	[ -d .build ] || mkdir .build
	$(CC) ./generate.py >$(TARGET)

.PHONY: test
test:
	$(CC) tests/validate_pipelines.py

.PHONY: clean
clean:
	rm -rf .build
