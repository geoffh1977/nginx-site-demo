# Build Kubernetes Helm Container For Use With Projects
FROM alpine:latest
MAINTAINER Geoffrey Harrison <geoff.harrison@bulletproof.net>

# Configure Dynamic Arguements
ARG VCS_REF
ARG BUILD_DATE

# Set Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/geoffreyharrison/meetup-madness-2017" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile"

RUN apk add --update nginx && rm -rf /var/cache/apk/* && \
  mkdir -p /tmp/nginx/client-body

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/default.conf /etc/nginx/conf.d/default.conf
COPY website /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]
