FROM steamcmd/steamcmd:latest
RUN apt update && apt-get install -y lua5.3
COPY steam_deploy.sh /root/steam_deploy.sh
COPY gma.lua /root/gma.lua
ENTRYPOINT ["/root/steam_deploy.sh"]
