# Blog Repo

Source for my blog available at: https://blog.hackervaillant.eu/

[/site](./site) contains my Hugo blog

[/deploy](./deploy) ansible playbook for server installation

## Usage

`make deploy_blog_full` is used for a full install with webserver config, certbot and dyndns setup

`make deploy_blog_content_only` is used to only upload the blog content
