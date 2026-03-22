FROM alpine:latest
LABEL Author="Victor Fernandez III, @cyberphor"
RUN apk add --no-cache python3 py3-pip openjdk17 py-requests
WORKDIR /opt/minecraft-server
COPY eula.txt eula.txt
COPY get_minecraft.py get_minecraft.py
COPY server.properties server.properties
RUN python3 get_minecraft.py
ENTRYPOINT [ "java", "-Xmx1024M", "-Xms1024M", "-jar", "minecraft.jar", "nogui" ]