FROM nginx:alpine
WORKDIR /var/www/html
COPY index.html /var/www/html/
CMD ["nginx" , "-g" , "demon off;"]
