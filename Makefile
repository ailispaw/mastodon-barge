vagrant:
	vagrant up --no-provision

build: Dockerfile
	vagrant provision --provision-with build

config:
	vagrant provision --provision-with config

setup:
	vagrant provision --provision-with setup

run:
	vagrant provision --provision-with mastodon

clean:
	vagrant destroy -f
	$(RM) -r .vagrant

.PHONY: vagrant build config setup run clean
