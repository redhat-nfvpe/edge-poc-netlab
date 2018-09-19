# Edge PoC - Virtual Networking Infrastructure

This repository contains Ansible roles and playbooks used to construct a
virtual network to be used for development and/or demonstration purposes.
These playbooks will build a virtual network on KVM and spin up two Top-Of-Rack
switches with ONIE (Open Network Install Environment).

First step to be able to execute these playbooks is to add the qcow2 image for the
switch under the folder "files". Then, you will have to modify the parameter "vm_disk",
with the correct name of that file in the VM definition files under the folder "nodes":

	vm_name: tor01
	vm_disk: cumulus_linux-3.6.2-vx-amd64.qcow2
	vm_type: tor

The command to execute this playbooks is:

	ansible-playbook -vvv playbooks/build.yaml -i inventory/hosts.dev

After the execution of the playbook finishes, two VMs should be running:


	> virsh list
	 Id    Name                           State
	----------------------------------------------------
	 127   tor02                          running
	 128   tor01                          running

Depending on the NOS that you're using (Cisco, Arista, Cumulus, etc) the VM could have
received an IP from libvirt DHCP, but a console interface has been defined and listening
to a specific port defined in the files under the "nodes" folder.

In order to connect to "tor01" you could do the following:

	telnet localhost 2001


In order to clean up the whole environment, you can use the following command:

	ansible-playbook -vvv playbooks/teardown.yaml -i inventory/hosts.dev


