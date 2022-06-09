BACKEND?=docker
CONCURRENCY?=1
CI_ARGS?=
PACKAGES?=

# Abs path only. It gets copied in chroot in pre-seed stages
LUET?=/usr/bin/luet
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/output
COMPRESSION?=zstd

TREE?=packages
REPO_CACHE?=quay.io/mocaccino/desktop
export REPO_CACHE
BUILD_ARGS?=--pull --no-spinner --only-target-package
SUDO?=sudo
VALIDATE_OPTIONS?=


ifneq ($(strip $(REPO_CACHE)),)
	BUILD_ARGS+=--image-repository $(REPO_CACHE)
endif

.PHONY: all
all: deps build

.PHONY: deps
deps:
	@echo "Installing luet"
	go get -u github.com/mudler/luet


.PHONY: clean
clean:
	$(SUDO) rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(ROOT_DIR)/build
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: build-all
build-all: clean
	mkdir -p $(ROOT_DIR)/build
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) --full --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild
rebuild:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild-all
rebuild-all:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) --full --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

repository:
	mkdir -p $(ROOT_DIR)/repository

repository/luet:
	git clone -b master --single-branch https://github.com/Luet-lab/luet-repo $(ROOT_DIR)/repository/luet

repository/extra:
	git clone -b master --single-branch https://github.com/mocaccinoos/mocaccino-extra $(ROOT_DIR)/repository/extra

repository/commons:
	git clone -b master --single-branch https://github.com/mocaccinoos/os-commons $(ROOT_DIR)/repository/commons

validate: repository repository/luet repository/extra repository/commons
	$(LUET) tree validate --tree $(ROOT_DIR)/repository --tree $(TREE) $(VALIDATE_OPTIONS)

.PHONY: create-repo
create-repo:
	$(SUDO) $(LUET) create-repo --tree "$(TREE)" \
    --output $(ROOT_DIR)/build \
    --packages $(ROOT_DIR)/build \
    --name "mocaccino-desktop" \
    --descr "Mocaccino Desktop Repo" \
    --urls "http://localhost:8000" \
    --tree-compression $(COMPRESSION) \
    --meta-compression $(COMPRESSION) \
    --type http

.PHONY: serve-repo
serve-repo:
	LUET_NOLOCK=true $(LUET) serve-repo --port 8000 --dir $(ROOT_DIR)/build

.PHONY: auto-bump
auto-bump:
	TREE_DIR=$(ROOT_DIR)/$(TREE) $(LUET) autobump-github

autobump: auto-bump

repo-validate:
	./scripts/repo_validate.sh