BLOG_FILES := $(shell find site/)

deploy/public: ${BLOG_FILES}
	hugo --source ./site --destination ../deploy/public/
	touch deploy/public # workaround invalid timestamp: https://github.com/gohugoio/hugo/issues/6161

.PHONY: deploy_blog_full
deploy_blog_full: deploy/public
	ansible-playbook --become -i 'blog.hackervaillant.eu,' playbook.yml

.PHONY: deploy_blog_content_only
deploy_blog_content_only: deploy/public
	ansible-playbook --become -i 'blog.hackervaillant.eu,' -t blog deploy/playbook.yml
