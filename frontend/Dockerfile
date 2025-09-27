FROM nginx:alpine

# Copy application files
COPY . /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create a script to inject environment variables
RUN echo '#!/bin/sh' > /docker-entrypoint.d/30-inject-config.sh && \
    echo 'envsubst < /usr/share/nginx/html/config.js.template > /usr/share/nginx/html/config.js' >> /docker-entrypoint.d/30-inject-config.sh && \
    chmod +x /docker-entrypoint.d/30-inject-config.sh

# Create config template
RUN mv /usr/share/nginx/html/config.js /usr/share/nginx/html/config.js.template

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
