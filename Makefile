# -*- mode: makefile -*-

CP = cp -R
MKDIR = mkdir -p
DOCKER = docker
COMPOSE = docker-compose

.PHONY: develop-copy-lib
develop-copy-lib:
	rm -rf ./example/develop/lib
	$(CP) ./lib ./example/develop

.PHONY: develop-run
develop-run: develop-copy-lib
	$(COMPOSE) up --build develop
