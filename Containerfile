# Use the official Nginx image as a base
FROM nginx:latest

# Create the directory where your web content will live
RUN mkdir -p /var/www
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    charset utf-8; \
    root /var/www; \
    index index.html; \
 \
     location = /logo.png { \
        try_files /logo.png =404; \
    } \
    location /images/ { \ 
        try_files $uri =404; \
    } \
    location ~ ^/(mobile|plain-text|desktop)/(light|dark)/ { \
        try_files $uri =404; \
    } \
    location /styles/ { \
        try_files $uri =404; \
    } \ 
    location = / { \
        return 301 /desktop/light/index.html; \
    } \
    location / { \
        return 301 /desktop/light/index.html; \
    } \
    location ~ ^(.*)/$ { \
        rewrite ^(.*)/$ $1/index.html break; \
    } \
    location /desktop/light/ { \
        index index.html; \
    } \
}'\ > /etc/nginx/conf.d/default.conf
# Copy your custom Nginx configuration (if you have one)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 for HTTP traffic
EXPOSE 80

# The VOLUME instruction is commented because it's better to handle volumes at runtime
# VOLUME ["/var/www/web"]

# Start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]
