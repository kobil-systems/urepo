# Use an official kobil runtime as a parent image
FROM git.scp.kobil.com:4567/ecoservers/eco-docker/ubuntu:18.04

ARG BUILD_DATE
ARG NAME
ARG DESCRIPTION
ARG VCS_REF
ARG VCS_URL
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name=$NAME \
      org.label-schema.description=$DESCRIPTION \
      org.label-schema.url="https://www.kobil.com/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.vendor="Kobil Systems Gmbh" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

USER appuser

COPY --chown=appuser:appuser _build/prod/rel/urepo /app

ENTRYPOINT ["/app/bin/urepo"]
