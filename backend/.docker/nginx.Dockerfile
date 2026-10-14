FROM nginx:alpine

WORKDIR /var/www/html

COPY public /var/www/html/public
COPY .docker/nginx.conf /etc/nginx/conf.d/default.conf

RUN rm -f /var/www/html/public/storage \
    && ln -s ../storage/app/public /var/www/html/public/storage

EXPOSE 80
