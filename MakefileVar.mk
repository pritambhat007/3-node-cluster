# Copyright 2018-present Open Networking Foundation
#
# SPDX-License-Identifier: Apache-2.0

SHELL		:= /bin/bash
MAKEDIR		:= $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
BUILD		?= $(MAKEDIR)/build
M           	?= $(BUILD)/milestones
SCRIPTDIR	:= $(MAKEDIR)/scripts
RESOURCEDIR	:= $(MAKEDIR)/resources
WORKSPACE	?= $(HOME)
VENV		?= $(BUILD)/venv/aiab

4G_CORE_VALUES       ?= $(MAKEDIR)/sd-core-4g-values.yaml
5G_CORE_VALUES       ?= $(MAKEDIR)/sd-core-5g-values.yaml
ROC_VALUES           ?= $(MAKEDIR)/roc-values.yaml
ROC_DEFAULTENT_MODEL ?= $(MAKEDIR)/roc-defaultent-model.json
ROC_4G_MODELS        ?= $(MAKEDIR)/roc-4g-models.json
ROC_5G_MODELS        ?= $(MAKEDIR)/roc-5g-models.json
TEST_APP_VALUES      ?= $(MAKEDIR)/5g-test-apps-values.yaml
GET_HELM              = get_helm.sh

DOCKER_VERSION    ?= '20.10'
HELM_VERSION	  ?= v3.6.3
KUBECTL_VERSION   ?= v1.23.0

RKE2_K8S_VERSION  ?= v1.23.4+rke2r1
K8S_VERSION       ?= v1.20.11

ENABLE_ROUTER ?= true
ENABLE_GNBSIM ?= true
ENABLE_SUBSCRIBER_PROXY ?= false
GNBSIM_COLORS ?= true

K8S_INSTALL ?= rke2
CTR_CMD     := sudo /var/lib/rancher/rke2/bin/ctr --address /run/k3s/containerd/containerd.sock --namespace k8s.io

PROXY_ENABLED   ?= false
HTTP_PROXY      ?= ${http_proxy}
HTTPS_PROXY     ?= ${https_proxy}
NO_PROXY        ?= ${no_proxy}

DATA_IFACE ?= data
ifeq ($(DATA_IFACE), data)
	RAN_SUBNET := 192.168.251.0/24
else
	RAN_SUBNET := $(shell ip route | grep $${DATA_IFACE} | awk '/kernel/ {print $$1}' | head -1)
	DATA_IFACE_PATH := $(shell find /*/systemd/network -maxdepth 1 -not -type d -name '*$(DATA_IFACE).network' -print)
	DATA_IFACE_CONF ?= $(shell basename $(DATA_IFACE_PATH)).d
endif

# systemd-networkd and systemd configs
LO_NETCONF            := /etc/systemd/network/20-aiab-lo.network
OAISIM_NETCONF        := $(LO_NETCONF) /etc/systemd/network/10-aiab-enb.netdev /etc/systemd/network/20-aiab-enb.network
ROUTER_POD_NETCONF    := /etc/systemd/network/10-aiab-dummy.netdev /etc/systemd/network/20-aiab-dummy.network
ROUTER_HOST_NETCONF   := /etc/systemd/network/10-aiab-access.netdev /etc/systemd/network/20-aiab-access.network /etc/systemd/network/10-aiab-core.netdev /etc/systemd/network/20-aiab-core.network /etc/systemd/network/$(DATA_IFACE_CONF)/macvlan.conf
UE_NAT_CONF           := /etc/systemd/system/aiab-ue-nat.service

# monitoring
RANCHER_MONITORING_CRD_CHART := rancher/rancher-monitoring-crd
RANCHER_MONITORING_CHART     := rancher/rancher-monitoring
MONITORING_VALUES            ?= $(MAKEDIR)/resources/monitoring.yaml

NODE_IP ?= $(shell ip route get 8.8.8.8 | grep -oP 'src \K\S+')
ifndef NODE_IP
$(error NODE_IP is not set)
endif

MME_IP  ?=

HELM_GLOBAL_ARGS ?=

# Allow installing local charts or specific versions of published charts.
# E.g., to install the Aether 1.5 release:
#    CHARTS=release-1.5 make test
# Default is to install from the latest charts.
CHARTS     ?= latest
CONFIGFILE := configs/$(CHARTS)
include $(CONFIGFILE)

cpu_family	:= $(shell lscpu | grep 'CPU family:' | awk '{print $$3}')
cpu_model	:= $(shell lscpu | grep 'Model:' | awk '{print $$2}')
os_vendor	:= $(shell lsb_release -i -s)
os_release	:= $(shell lsb_release -r -s)
USER		:= $(shell whoami)

