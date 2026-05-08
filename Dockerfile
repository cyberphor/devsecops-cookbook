FROM alpine:3.23
LABEL image.authors="Vic Fernandez III <@cyberphor>"
WORKDIR /home/remy/
RUN apk add --no-cache --update python3 py3-pip &&\
    pip install --break-system-packages mkdocs-material &&\
    adduser -D remy -h /home/remy 
COPY entrypoint.sh entrypoint.sh
COPY mkdocs.yml mkdocs.yml
COPY recipes/ recipes/
RUN chown -R remy:remy /home/remy &&\
    chmod +x entrypoint.sh
USER remy
EXPOSE 8080
ENTRYPOINT [ "./entrypoint.sh" ]
