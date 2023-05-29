# Copyright 2018-present Open Networking Foundation
#
# SPDX-License-Identifier: Apache-2.0

3_NODE := 3-node-cluster

3-node-cluster: $(M)/3-node-cluster
$(M)/3-node-cluster: $(M)/setup
	sudo sshpass -p $(PASSWD) ssh -o StrictHostKeyChecking=no $(A-NODE) "cd /home/ubuntu/ansible/;ls"
	sudo sshpass -p $(PASSWD) ssh -o StrictHostKeyChecking=no $(A-NODE) "ansible-playbook /home/ubuntu/ansible/cluster.yml -i /home/ubuntu/ansible/host.ini"
	curl -LO "https://dl.k8s.io/release/$(KUBECTL_VERSION)/bin/linux/amd64/kubectl"
	sudo chmod +x kubectl
	sudo mv kubectl /usr/local/bin/
	kubectl version --client
	mkdir -p $(HOME)/.kube
	sudo cp /etc/rancher/rke2/rke2.yaml $(HOME)/.kube/config
	sudo chown -R $(shell id -u):$(shell id -g) $(HOME)/.kube
	touch $@
	kubectl get nodes -o wide
	make router-pod
	make net-prep
	make 5g-roc
	make 5g-monitoring
	make 5g-core
	make 5g-test


