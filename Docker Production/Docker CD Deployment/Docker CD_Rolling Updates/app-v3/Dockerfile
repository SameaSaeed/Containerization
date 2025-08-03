FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
# Simulate a configuration error
RUN echo "error_page 404 /50x.html;" >> /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]