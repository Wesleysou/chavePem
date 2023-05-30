#!/usr/bin/env bash

#-VARIAVEIS PROGRAMA-------------------------------------------------#

# Dê permissão de execução para este script ~~> chmod 777 generateSSL.sh (ou o nome que vc renomear ele)
DOMAIN=backbefitsptech
SUFIX=.hopto.org:8080
APP_SERVER=localhost
APP_PORT=8080
APP_PROTOCOL=http #troque se nao for usar localhost

#-VARIAVEIS INFO-----------------------------------------------------#

NOME_PROGRAMA="$(basename $0 | cut -d. -f1)"
VERSAO="1.0"
AUTOR="Don616"
CONTATO="https://github.com/Don616"
DESCRICAO="Gerador de SSL usando LetsEncrypt e Nginx"
varEXE=$1 # Se não tiver parametros ela executa normal

#-VARIAVEIS PARAMETRO----------------------------------------------------#

varINFO="
Nome do Programa: $NOME_PROGRAMA
Autor: $AUTOR
Versão: $VERSAO
Descrição do Programa: $DESCRICAO
"
varHELP="
Instruções para Ajuda:
	-h ou --help: Abre a ajuda de comandos do usuário;
	-i ou --info: Informações sobre o programa;
"

#-TESTES--------------------------------------------------------------------------#



#-LOOP PARA RODAR MAIS PARAMETROS---------------------------------------------------#

while test -n "$1"; do

	case $1 in

		-i |  --info)  	echo "$varINFO" 											;;		
		-h |  --help)  	echo "$varHELP"												;;
		-d | --debug)	bash -x $0													;;
				   *) 	echo "\nComando inválido. Digite -h ou --help para ajuda\n"	;;

	esac
	shift

done
#-FUNÇÕES--------------------------------------------------------------------------#
install(){

sudo apt update -y
sudo apt install nginx -y 
sudo ufw enable

}

permissions(){

sudo mkdir -p /var/www/$DOMAIN/html
sudo chown -R $USER:$USER /var/www
sudo chown -R $USER:$USER /var/www/$DOMAIN/html
sudo chmod -R 755 /var/www/$DOMAIN
sudo chown -R $USER:$USER /etc/nginx/sites-available
sudo chown -R $USER:$USER /etc/nginx
sudo chmod -R 755 /etc/nginx/sites-available
sudo chmod -R 755 /etc/nginx
sudo touch /var/www/$DOMAIN/html/index.html
sudo touch /etc/nginx/sites-available/$DOMAIN
sudo echo 'Olá mundo' > /var/www/$DOMAIN/html/index.html

}

nginx_setup(){

sudo cat <<EOF >> /etc/nginx/sites-available/$DOMAIN
server {
        listen 80;
        listen [::]:80;

        root /var/www/$DOMAIN/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $DOMAIN www.$DOMAIN$SUFIX;

        location / {
                try_files $uri $uri/ =404;
        }
}
EOF

sudo ln -s /etc/nginx/sites-available/$DOMAIN	 /etc/nginx/sites-enabled/
sudo systemctl restart nginx

sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'
sudo ufw allow ssh

}

certbot_install(){

sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx --preferred-chain "DST Root CA X3" -d $DOMAIN$SUFIX -d www.$DOMAIN$SUFIX

}

set_proxy(){

sudo cat <<EOF > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

    server {
        listen 80;
        server_name $DOMAIN$SUFIX;

        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name $DOMAIN$SUFIX;

        ssl_certificate /etc/letsencrypt/live/$DOMAIN$SUFIX/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN$SUFIX/privkey.pem;

    location / {
        proxy_pass $APP_PROTOCOL://$APP_SERVER:$APP_PORT;

        # Configurações para habilitar SSL no backend
        proxy_ssl_server_name on;
        proxy_ssl_verify off;
    }
}

	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;


	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	gzip on;

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
EOF
sudo systemctl restart nginx

}

docker_frontend(){
curl -fsSL https://get.docker.com | sh    
sudo chmod 777 /var/run/docker.sock
sudo docker run -d -p $APP_PORT:80 --rm --name teste-frontend don616/open:frontend-nginx-ssl
}

main(){

    install
    permissions
    nginx_setup
    certbot_install
    set_proxy
    docker_frontend
    echo -e "\nTeste o seu site: https://$DOMAIN$SUFIX"

}

#-EXECUÇÃO-------------------------------------------------------------------------#

if [ -z "$varEXE" ]; then
	main
fi
