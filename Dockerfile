FROM ubuntu:20.04 AS builder
# Instala dependencias necesarias
RUN apt-get update && apt -y upgrade
RUN apt-get install -y software-properties-common curl
RUN add-apt-repository ppa:openjdk-r/ppa
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt update
RUN apt install -y git openjdk-8-jdk openjdk-11-jdk unzip nodejs

ENV SENCHA_CMD_VERSION_FULL="7.8.0.59"

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"
ENV INSTALL4J_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN apt-get clean
RUN curl -o /tmp/cmd.zip http://cdn.sencha.com/cmd/${SENCHA_CMD_VERSION_FULL}/no-jre/SenchaCmd-${SENCHA_CMD_VERSION_FULL}-linux-amd64.sh.zip
RUN unzip -qp /tmp/cmd.zip > /tmp/cmd
RUN mkdir -p /opt/Sencha
RUN bash /tmp/cmd -q -dir /opt/Sencha
RUN rm -rf /tmp/cmd*
ENV PATH="/opt/Sencha:$PATH"

# Carpeta de trabajo
WORKDIR /app

COPY legacy/package*.json ./

# Instalar dependencias y compilar
RUN npm install

# Copiar archivos del proyecto
COPY ./legacy/ .

RUN npm run postinstall

RUN npm run build

# --- Etapa final (para Traefik) ---
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/web/ ./
EXPOSE 80

# # Etapa final con apache
# FROM httpd:2.4
# RUN rm -rf /usr/local/apache2/htdocs/*
# COPY --from=builder /app/web/ /usr/local/apache2/htdocs/

# # Habilitar mod_proxy
# RUN sed -i \
#     -e 's/^#\(LoadModule proxy_module modules\/mod_proxy.so\)/\1/' \
#     -e 's/^#\(LoadModule proxy_http_module modules\/mod_proxy_http.so\)/\1/' \
#     -e 's/^#\(LoadModule proxy_wstunnel_module modules\/mod_proxy_wstunnel.so\)/\1/' \
#     conf/httpd.conf

# COPY ./httpd-vhost.conf /usr/local/apache2/conf/extra/httpd-vhost.conf
# RUN echo "Include conf/extra/httpd-vhost.conf" >> /usr/local/apache2/conf/httpd.conf