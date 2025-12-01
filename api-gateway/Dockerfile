FROM nginx:alpine

# Установка envsubst для подстановки переменных окружения
RUN apk add --no-cache gettext

COPY nginx.conf /etc/nginx/templates/nginx.conf.template

EXPOSE 80

CMD ["/bin/sh", "-c", "envsubst '$$ALLOWED_ORIGIN' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]