# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GO ?= go
EPOCH_TEST_COMMIT ?= f2925f58acc259c4b894353f5fc404bdeb40028e
PROJECT := github.com/kubernetes-incubator/cri-containerd
BINDIR ?= ${DESTDIR}/usr/local/bin
BUILD_DIR ?= _output

all: binaries

default: help

help:
	@echo "Usage: make <target>"
	@echo
	@echo " * 'install'       - Install binaries to system locations"
	@echo " * 'binaries'      - Build cri-containerd"
	@echo " * 'clean'         - Clean artifacts"
	@echo " * 'verify'        - Execute the source code verification tools"
	@echo " * 'install.tools' - Installs tools used by verify"
	@echo " * 'uninstall'     - Remove installed binaries from system locations"

.PHONY: check-gopath

check-gopath:
ifndef GOPATH
	$(error GOPATH is not set)
endif

verify: lint gofmt

lint: check-gopath
	@./hack/repo-infra/verify/go-tools/verify-gometalinter.sh
	@./hack/repo-infra/verify/verify-go-src.sh -r $(shell pwd) -v
	@./hack/repo-infra/verify/verify-boilerplate.sh

gofmt:
	@./hack/repo-infra/verify/go-tools/verify-gofmt.sh

cri-containerd: check-gopath
	$(GO) build -o $(BUILD_DIR)/$@ \
		$(PROJECT)/cmd/cri-containerd

clean:
	rm -f $(BUILD_DIR)/cri-containerd

binaries: cri-containerd

install: check-gopath
	install -D -m 755 $(BUILD_DIR)/cri-containerd $(BINDIR)/cri-containerd

uninstall:
	rm -f $(BINDIR)/cri-containerd

.PHONY: .gitvalidation
# When this is running in travis, it will only check the travis commit range
.gitvalidation: check-gopath
ifeq ($(TRAVIS),true)
	git-validation -q -run DCO,short-subject
else
	git-validation -v -run DCO,short-subject -range $(EPOCH_TEST_COMMIT)..HEAD
endif

.PHONY: install.tools .install.gitvalidation .install.gometalinter

install.tools: .install.gitvalidation .install.gometalinter

.install.gitvalidation:
	go get -u github.com/vbatts/git-validation

.install.gometalinter:
	go get -u github.com/alecthomas/gometalinter
	gometalinter --install

.PHONY: \
	binaries \
	clean \
	default \
	gofmt \
	help \
	install \
	lint \
	uninstall
