FROM nginx:alpineFROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

# Copy application filesCOPY index.html /usr/share/nginx/html/

COPY index.html /usr/share/nginx/html/COPY athens_high_school.glb /usr/share/nginx/html/

COPY athens_high_school.glb /usr/share/nginx/html/COPY running.mp3 /usr/share/nginx/html/

COPY running.mp3 /usr/share/nginx/html/COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

# Copy nginx configurationCMD ["nginx", "-g", "daemon off;"]
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
