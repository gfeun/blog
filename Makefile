BLOG_FILES := $(shell find site/)
SSH_PRIVATE_KEY := ~/.ssh/id_rsa

ifeq ($(DO_TOKEN),)
$(error DO_TOKEN is not set)
endif

deploy/public: ${BLOG_FILES}
	hugo --source ./site --destination ../deploy/public/
	touch deploy/public # workaround invalid timestamp: https://github.com/gohugoio/hugo/issues/6161

.PHONY: install_blog
install_blog: deploy/public
	# Taint provisionning resource to run ansible every time
	-cd deploy && terraform taint null_resource.ansible_provisionning
	cd deploy && terraform apply -auto-approve -input=false -var "do_token=${DO_TOKEN}" -var "ssh_private_key_file=${SSH_PRIVATE_KEY}"

.PHONY: destroy_blog
destroy_blog:
	cd deploy && terraform destroy -auto-approve -input=false -var "do_token=${DO_TOKEN}" -var "ssh_private_key_file=${SSH_PRIVATE_KEY}"

.PHONY: reinstall_blog
reinstall_blog: destroy_blog install_blog
