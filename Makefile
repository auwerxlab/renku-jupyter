# -*- coding: utf-8 -*-
#
# Copyright 2017-2019 - Swiss Data Science Center (SDSC)
# A partnership between École Polytechnique Fédérale de Lausanne (EPFL) and
# Eidgenössische Technische Hochschule Zürich (ETHZ).
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

extensions = \
	r \
	cuda-9.2 cuda-10.0-tensorflow-1.14

DOCKER_PREFIX?=auwerxlab/singleuser
DOCKER_LABEL?=latest
JUPYTERHUB_VERSION?=0.9.6
GIT_MASTER_HEAD_SHA:=$(shell git rev-parse --short=7 --verify HEAD)
RVERSION?=3.5.2
R_TAG=-r$(RVERSION)
RENKU_VERSION?=0.7.1

ifdef RENKU_VERSION
	RENKU_PIP_SPEC="--spec renku==$(RENKU_VERSION)"
	RENKU_TAG=-renku$(RENKU_VERSION)
endif

.PHONY: base all

all: base $(extensions)

base:
	docker build docker/base \
		--build-arg RENKU_PIP_SPEC=$(RENKU_PIP_SPEC) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		-t $(DOCKER_PREFIX):$(DOCKER_LABEL)$(RENKU_TAG) && \
	docker tag $(DOCKER_PREFIX):$(DOCKER_LABEL)$(RENKU_TAG) $(DOCKER_PREFIX):$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG)

login:
	@echo "${DOCKER_PASSWORD}" | docker login -u="${DOCKER_USERNAME}" --password-stdin ${DOCKER_REGISTRY}

push:
	for ext in "" $(extensions) ; do \
		if test "$$ext" != "" ; then \
			ext=-$$ext; \
		fi; \
		docker push $(DOCKER_PREFIX)$$ext:$(DOCKER_LABEL)$(RENKU_TAG) ; \
		docker push $(DOCKER_PREFIX)$$ext:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG) ; \
	done

pull:
	for ext in "" $(extensions) ; do \
		if test "$$ext" != "" ; then \
			ext=-$$ext; \
		fi; \
		docker pull $(DOCKER_PREFIX)$$ext:$(DOCKER_LABEL) ; \
	done

r:
	docker build docker/r \
		--build-arg RENKU_PIP_SPEC=$(RENKU_PIP_SPEC) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		--build-arg RVERSION=$(RVERSION) \
		-t $(DOCKER_PREFIX)-r:$(DOCKER_LABEL)$(RENKU_TAG)$(R_TAG) && \
	docker tag $(DOCKER_PREFIX)-r:$(DOCKER_LABEL)$(RENKU_TAG)$(R_TAG) $(DOCKER_PREFIX)-r:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG)$(R_TAG)

%:
	cd docker/$@ && \
	docker build \
		--build-arg RENKU_PIP_SPEC=${RENKU_PIP_SPEC} \
		--build-arg BASE_IMAGE=$(DOCKER_PREFIX):$(DOCKER_LABEL)$(RENKU_TAG) \
		-t $(DOCKER_PREFIX)-$@:$(DOCKER_LABEL)$(RENKU_TAG) . && \
	docker tag $(DOCKER_PREFIX)-$@:$(DOCKER_LABEL)$(RENKU_TAG) $(DOCKER_PREFIX)-$@:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG)

