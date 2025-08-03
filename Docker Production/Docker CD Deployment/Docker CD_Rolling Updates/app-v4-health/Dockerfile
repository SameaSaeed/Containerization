FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
COPY health.html /usr/share/nginx/html/health
EXPOSE 80

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]