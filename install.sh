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
sudo mkdir -p /opt/ollama-models
sudo chown root:root /opt/ollama-api
sudo chown root:root /opt/ollama-models

# Copy application files
sudo cp app.js package.json /opt/ollama-api/
cd /opt/ollama-api

# Install dependencies
sudo npm install --production

# Create systemd service for Ollama
sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=3
Environment=OLLAMA_MODELS=/opt/ollama-models

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
User=root
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

# Pull a smaller model for better performance
echo "Pulling TinyLlama model..."
ollama pull tinyllama

# Update app.js to use the correct default model
sudo sed -i 's/deepseek-r1:8b/tinyllama:latest/g' /opt/ollama-api/app.js

# Start API server
sudo systemctl start ollama-api

echo "Installation complete!"
echo "API server running on port 8080"
echo "Test with: curl -X POST http://localhost:8080/chat -H 'Content-Type: application/json' -d '{\"user_message\":\"Hello\"}'"
