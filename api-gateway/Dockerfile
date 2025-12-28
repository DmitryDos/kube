FROM nginx:alpine

RUN apk add --no-cache gettext && \
    mkdir -p /etc/nginx/ssl

COPY nginx.conf /etc/nginx/templates/nginx.conf.template

EXPOSE 80 443

CMD ["/bin/sh", "-c", "envsubst '$$ALLOWED_ORIGIN' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]