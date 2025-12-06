#!/bin/bash
set -e

echo "Installing Ollama DeepSeek API Server on Ubuntu..."

# Update system
sudo apt-get update

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Create app directory
sudo mkdir -p /opt/ollama-api
sudo chown $USER:$USER /opt/ollama-api

# Copy application files
cp app.js package.json /opt/ollama-api/
cd /opt/ollama-api

# Install dependencies
npm install --production

# Create systemd service for Ollama
sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=3
Environment=OLLAMA_MODELS=/home/$USER/.ollama/models

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for API server
sudo tee /etc/systemd/system/ollama-api.service > /dev/null <<EOF
[Unit]
Description=Ollama API Server
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/ollama-api
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=3
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl enable ollama-api
sudo systemctl start ollama

# Wait for Ollama to start
echo "Waiting for Ollama to start..."
sleep 10

# Pull the DeepSeek model
echo "Pulling DeepSeek model..."
ollama pull deepseek-r1:8b

# Start API server
sudo systemctl start ollama-api

echo "Installation complete!"
echo "API server running on port 8080"
echo "Test with: curl -X POST http://localhost:8080/chat -H 'Content-Type: application/json' -d '{\"user_message\":\"Hello\"}'"
