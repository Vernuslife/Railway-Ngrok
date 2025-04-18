FROM ubuntu

ARG NGROK_TOKEN
ARG REGION=jp

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    ssh \
    wget \
    unzip \
    vim \
    curl \
    python3

# 下载并解压 ngrok
RUN wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O /ngrok-stable-linux-amd64.zip \
 && cd / && unzip ngrok-stable-linux-amd64.zip \
 && chmod +x /ngrok

# 入口脚本：启动 ngrok、打印 ssh 命令、再启动 sshd
RUN mkdir /run/sshd \
 && tee /openssh.sh << 'EOF' \
   /ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 & \
   sleep 5 \
   curl -s http://localhost:4040/api/tunnels | python3 -c "import sys,json;u=json.load(sys.stdin)['tunnels'][0]['public_url'];print('SSH 连接命令: ssh root@'+u[6:].replace(':',' -p '));print('ROOT 默认密码: akashi520')" \
   || echo "Error：请检查 NGROK_TOKEN 是否正确，或对应区域的节点被占用" \
   /usr/sbin/sshd -D \
EOF \
 && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
 && echo root:akashi520 | chpasswd \
 && chmod +x /openssh.sh

EXPOSE 4040 22

CMD ["/openssh.sh"]

