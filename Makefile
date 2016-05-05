PACKAGE = gmp
ORG = amylum

BUILD_DIR = /tmp/$(PACKAGE)-build
RELEASE_DIR = /tmp/$(PACKAGE)-release
RELEASE_FILE = /tmp/$(PACKAGE).tar.gz
PATH_FLAGS = --prefix=/usr --infodir=/tmp/trash
CONF_FLAGS = --enable-maintainer-mode --enable-static --disable-padlock-support
CFLAGS = -static -static-libgcc -Wl,-static -lc -fPIC

PACKAGE_VERSION = 6.1.0
PATCH_VERSION = $$(cat version)
VERSION = $(PACKAGE_VERSION)-$(PATCH_VERSION)

SOURCE_URL = https://gmplib.org/download/gmp/gmp-$(PACKAGE_VERSION).tar.xz
SOURCE_PATH = /tmp/source
SOURCE_TARBALL = /tmp/source.tar.gz

.PHONY : default source deps manual container deps build version push local

default: container

source:
	rm -rf $(SOURCE_PATH) $(SOURCE_TARBALL)
	mkdir $(SOURCE_PATH)
	curl -sLo $(SOURCE_TARBALL) $(SOURCE_URL)
	tar -x -C $(SOURCE_PATH) -f $(SOURCE_TARBALL) --strip-components=1

manual:
	./meta/launch /bin/bash || true

container:
	./meta/launch

deps:

build: source deps
	rm -rf $(BUILD_DIR)
	cp -R $(SOURCE_PATH) $(BUILD_DIR)
	cd $(BUILD_DIR) && CC=musl-gcc CFLAGS='$(CFLAGS) $(LIBGPG-ERROR_PATH)' ./configure $(PATH_FLAGS) $(CONF_FLAGS)
	cd $(BUILD_DIR) && make DESTDIR=$(RELEASE_DIR) install
	rm -rf $(RELEASE_DIR)/tmp
	mkdir -p $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)
	cp $(BUILD_DIR)/COPYING $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)/LICENSE
	cd $(RELEASE_DIR) && tar -czvf $(RELEASE_FILE) *

version:
	@echo $$(($(PATCH_VERSION) + 1)) > version

push: version
	git commit -am "$(VERSION)"
	ssh -oStrictHostKeyChecking=no git@github.com &>/dev/null || true
	git tag -f "$(VERSION)"
	git push --tags origin master
	@sleep 3
	targit -a .github -c -f $(ORG)/$(PACKAGE) $(VERSION) $(RELEASE_FILE)
	@sha512sum $(RELEASE_FILE) | cut -d' ' -f1

local: build push

