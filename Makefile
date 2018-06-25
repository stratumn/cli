# Tooling parameters
SHELL=/bin/bash
KEYBASE_SIGN=keybase pgp sign

# Go parameters
GOCMD=go
GOGET=$(GOCMD) get
GOBUILD=$(GOCMD) build

# Build parameters
CMD_NAME=indigo-cli
NIX_OS_ARCHS?=darwin-amd64 linux-amd64
WIN_OS_ARCHS?=windows-amd64
DIST_DIR=dist
NIX_EXECS=$(foreach os-arch, $(NIX_OS_ARCHS), $(DIST_DIR)/$(os-arch)/$(CMD_NAME))
WIN_EXECS=$(foreach os-arch, $(WIN_OS_ARCHS), $(DIST_DIR)/$(os-arch)/$(CMD_NAME).exe)
EXECS=$(NIX_EXECS) $(WIN_EXECS)
SIGNATURES=$(foreach exec, $(EXECS), $(exec).sig)
NIX_ZIP_FILES=$(foreach os-arch, $(NIX_OS_ARCHS), $(DIST_DIR)/$(os-arch)/$(CMD_NAME).zip)
WIN_ZIP_FILES=$(foreach os-arch, $(WIN_OS_ARCHS), $(DIST_DIR)/$(os-arch)/$(CMD_NAME).zip)
ZIP_FILES=$(NIX_ZIP_FILES) $(WIN_ZIP_FILES)

# Github parameters
GIT_COMMIT=$(shell git rev-parse HEAD)
GIT_PATH=$(shell git rev-parse --show-toplevel)
GITHUB_REPO=$(shell basename $(GIT_PATH))
GITHUB_USER=$(shell basename $(shell dirname $(GIT_PATH)))
VERSION=$(shell ./version.sh)
GENERATOR_VERSION=$(shell ./version.sh -g)
GIT_TAG=v$(VERSION)

# Release parameters
GITHUB_RELEASE_CMD=github-release
GITHUB_RELEASE_FLAGS=--user '$(GITHUB_USER)' --repo '$(GITHUB_REPO)' --tag '$(GIT_TAG)'
GITHUB_RELEASE_RELEASE=$(GITHUB_RELEASE_CMD) release $(GITHUB_RELEASE_FLAGS) --name '$(GIT_TAG)'
GITHUB_RELEASE_EDIT=$(GITHUB_RELEASE_CMD) edit $(GITHUB_RELEASE_FLAGS) --name '$(GIT_TAG)'
GITHUB_RELEASE_UPLOAD=$(GITHUB_RELEASE_CMD) upload $(GITHUB_RELEASE_FLAGS)

# Project files
LICENSED_FILES=$(shell find * -name '*.go' -not -path "vendor/*" | grep -v '^\./\.')
GITHUB_UPLOAD_FILES=$(foreach file, $(ZIP_FILES), github_upload_$(firstword $(subst ., ,$(file))))

TMP_DIR:=$(shell mktemp -d)

# == .PHONY ===================================================================
.PHONY: deps build clean lint test test_headers git_tag github_draft github_upload github_publish $(LICENSED_FILES) $(GITHUB_UPLOAD_FILES)

# == release ==================================================================
release: deps lint clean build git_tag github_draft github_upload github_publish

# == deps =====================================================================
deps:
	$(GOGET) github.com/golang/dep/cmd/dep
	$(GOGET) github.com/golangci/golangci-lint/cmd/golangci-lint
	dep ensure

# == build ====================================================================
build: $(EXECS)

BUILD_OS_ARCH=$(word 2, $(subst /, ,$@))
BUILD_OS=$(firstword $(subst -, ,$(BUILD_OS_ARCH)))
BUILD_ARCH=$(lastword $(subst -, ,$(BUILD_OS_ARCH)))
BUILD_COMMAND=$(firstword $(word 1, $(subst ., ,$(lastword $(subst /, ,$@)))))

$(EXECS):
	GOOS=$(BUILD_OS) GOARCH=$(BUILD_ARCH) $(GOBUILD) -o $@

# == sign =====================================================================
sign: $(SIGNATURES)

%.sig: %
	$(KEYBASE_SIGN) -d -i $* -o $@

# == zip ======================================================================
zip: $(ZIP_FILES)

ZIP_TMP_OS_ARCH_DIR=$(TMP_DIR)/$(BUILD_OS_ARCH)
ZIP_TMP_CMD_DIR=$(ZIP_TMP_OS_ARCH_DIR)/$(BUILD_COMMAND)

%.zip: %.exe %.exe.sig
	mkdir -p $(ZIP_TMP_CMD_DIR)
	cp $*.exe $(ZIP_TMP_CMD_DIR)
	cp $*.exe.sig $(ZIP_TMP_CMD_DIR)
	cp $(TEXT_FILES) $(ZIP_TMP_CMD_DIR)
	mv $(ZIP_TMP_CMD_DIR)/LICENSE $(ZIP_TMP_CMD_DIR)/LICENSE.txt
	cd $(ZIP_TMP_OS_ARCH_DIR) && zip -r $(BUILD_COMMAND){.zip,} 1>/dev/null
	cp $(ZIP_TMP_CMD_DIR).zip $@

%.zip: % %.sig
	mkdir -p $(ZIP_TMP_CMD_DIR)
	cp $* $(ZIP_TMP_CMD_DIR)
	cp $*.sig $(ZIP_TMP_CMD_DIR)
	cp $(TEXT_FILES) $(ZIP_TMP_CMD_DIR)
	cd $(ZIP_TMP_OS_ARCH_DIR) && zip -r $(BUILD_COMMAND){.zip,} 1>/dev/null
	cp $(ZIP_TMP_CMD_DIR).zip $@

# == clean ====================================================================
clean:
	$(GOCMD) clean
	rm -rf $(DIST_DIR)

# == lint =====================================================================
lint:
	golangci-lint run --deadline=4m --tests=false

# == test =====================================================================
test:
	$(GOCMD) test ./...

# == test_headers =============================================================
test_headers:
	@ ./test_headers.sh $(LICENSED_FILES)

# == git_tag ==================================================================
git_tag:
	git tag $(GIT_TAG)
	git push origin --tags

# == github_draft =============================================================
github_draft:
	echo $(GITHUB_RELEASE_RELEASE) --draft; \
	$(GITHUB_RELEASE_RELEASE) --draft; \

# == github_upload ============================================================
github_upload: $(GITHUB_UPLOAD_LIST)

$(GITHUB_UPLOAD_LIST): github_upload_%: %.zip
	$(GITHUB_RELEASE_UPLOAD) --file $*.zip --name $(BUILD_COMMAND)-$(BUILD_OS_ARCH).zip

# == github_publish ===========================================================
github_publish:
	echo $(GITHUB_RELEASE_EDIT); \
	$(GITHUB_RELEASE_EDIT); \