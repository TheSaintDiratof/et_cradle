#!/usr/bin/env bash 
podman build -t my-nginx .

podman run --replace -d \
  -p 8080:80 \
  -v "$PWD/output:/var/www" \
  --name my-nginx-container \
  my-nginx
