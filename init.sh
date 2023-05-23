sudo apt update

# Install nvm

echo "Installing nvm"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

source ~/.bashrc

nvm install 16

# install docker

sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install docker-ce
sudo systemctl enable docker
sudo usermod -aG docker ${USER}
su - ${USER}
sudo usermod -aG docker $USER

# Install certbot

echo "Installing certbot"

sudo apt install certbot python3-certbot-nginx

# Install nginx

echo "Installing nginx"

sudo yum install nginx -y
udo service nginx stop

# config certbot

sudo su -

sudo certbot --nginx -d taurus-site.duckdns.org
sudo systemctl status certbot.timer
sudo certbot renew --dry-run
