#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Update system packages
echo "Hi! Shamim!"
echo "Updating system packages..."
sudo apt update -y && sudo apt upgrade -y

# Install dependencies
sudo apt install -y nginx openssl curl

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
else
    echo "Docker is already installed."
fi


# Fetch the latest Docker Compose version
echo "Fetching the latest Docker Compose version..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')

# Download and install Docker Compose
echo "Installing Docker Compose version: $LATEST_VERSION..."
sudo curl -L "https://github.com/docker/compose/releases/download/${LATEST_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Set execute permissions
sudo chmod +x /usr/local/bin/docker-compose

# Enable Docker Compose autocompletion (optional)
# echo "Setting up autocompletion..."
# sudo curl -L "https://raw.githubusercontent.com/docker/compose/${LATEST_VERSION}/contrib/completion/bash/docker-compose" -o /etc/bash_completion.d/docker-compose
# source /etc/bash_completion.d/docker-compose

# Verify Docker Compose installation
echo "Docker Compose version installed:"
docker-compose version

# Set environment variables
export PUBLIC_IP=$(curl -s ifconfig.me)

# Create SSL directory
cd /
mkdir -p /etc/nginx/ssl

# Generate a Self-Signed Certificate for HTTPS
echo "Generating self-signed SSL certificate..."
openssl req -x509 -newkey rsa:4096 -keyout /etc/nginx/ssl/selfsigned.key \
-out /etc/nginx/ssl/selfsigned.crt -days 365 -nodes \
-subj "/C=US/ST=State/L=City/O=MyCompany/OU=IT/CN=$PUBLIC_IP"

# Set correct permissions
chmod 600 /etc/nginx/ssl/selfsigned.key
chmod 644 /etc/nginx/ssl/selfsigned.crt

# Configure Nginx as a reverse proxy with WebSocket support
echo "Configuring Nginx..."
cat > /etc/nginx/sites-available/fastapi <<EOF
# Redirect all http request to https reqquest.
server {
    listen 80;
    server_name _;
    return 301 https://\$host\$request_uri;
}


# Proxy for https request. 
server {
    listen 443 ssl;
    server_name _;
    ssl_certificate /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        proxy_redirect off;
        proxy_pass_header Set-Cookie;  # Allows cookies to pass through
    }
}
EOF

# Enable the Nginx configuration
ln -s /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Print success message
echo "FastAPI app deployed with HTTPS at https://$PUBLIC_IP/"
                                                                           