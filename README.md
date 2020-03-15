# Blog Repo

[/site]() contains my Hugo blog

[/deploy]() contains terraform for infrastructure setup and ansible playbook for server installation

# Usage

`make install_blog` is used for first install and blog updates

- It first builds the blog using [Hugo](https://gohugo.io/) static site generator
- Then it creates or updates the infrastructure using Terraform
- Finally it provisions the blog on the server

`make destroy_blog` deletes the infrastructure

`make reinstall_blog` is a helper to run destroy_blog and install_blog successively
