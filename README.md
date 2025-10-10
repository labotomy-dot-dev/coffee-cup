# Coffee cup
<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Lab info](#lab-info)
- [Lab setup](#lab-setup)
- [Lab up](#lab-up)

<!-- TOC end -->

## Lab info

Just my playground for argocd.

**Requirements:**

- docker
- kind
- kubectl
- helm
- Taskfile

## Lab setup

Install devbox to install all lab tools expect for docker or install all of them any other way. Here's
the setup for devbox:

```bash
curl -fsSL https://get.jetify.com/devbox | bash
```

And install packages:

```bash
devbox install
```

Finally run shell:

```bash
devbox shell
```

## Lab up

Run full lab:

```bash
task lab.up
```

Use Taskfile other commands to manage ArgoCD.
