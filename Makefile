# -*- mode: makefile -*-

CP = cp -R
MKDIR = mkdir -p
DOCKER = docker
COMPOSE = docker-compose
OPMRC = ./tools/.opmrc
OPM_DOCKER_IMAGE = nginxguardjwt_opm

.PHONY: develop-copy-lib
develop-copy-lib:
	rm -rf ./example/develop/lib
	$(CP) ./lib ./example/develop

.PHONY: develop-run
develop-run: develop-copy-lib
	$(COMPOSE) up --build develop

.PHONY: opm-docker-image-build
opm-docker-image-build:
	touch $(OPMRC)
	echo "github_token=$(OPM_GITHUB_TOKEN)" > $(OPMRC)
	echo "github_account=dailymotion" >> $(OPMRC)
	echo "upload_server=https://opm.openresty.org" >> $(OPMRC)
	echo "download_server=https://opm.openresty.org" >> $(OPMRC)
	$(DOCKER) build -t $(OPM_DOCKER_IMAGE) ./tools/

.PHONY: opm-build
opm-build: opm-docker-image-build
	$(DOCKER) run -it --rm -v $(PWD):/tmp/opm $(OPM_DOCKER_IMAGE) build

.PHONY: opm-upload
opm-upload: opm-build
	$(DOCKER) run -it --rm -v $(PWD):/tmp/opm $(OPM_DOCKER_IMAGE) upload
