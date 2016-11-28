#!/bin/sh

docker run -it --rm -p 443:443 -p 80:80 \
   --name certgrabbermake  -v "${certdir}/etc:/etc/letsencrypt" \
    -v "${certdir}/lib:/var/lib/letsencrypt" \
    quay.io/letsencrypt/letsencrypt:latest certonly \
    -d ${fqdn}  --email "${owner_email}" \
    --non-interactive  --agree-tos --standalone