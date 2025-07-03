#!/bin/bash

set -e

echo "🟢 Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "📦 Instalando dependências do sistema..."
sudo apt install -y python3 python3-pip python3-venv git build-essential curl tesseract-ocr tesseract-ocr-por poppler-utils unzip

echo "📁 Criando estrutura do projeto em /opt/docling"
sudo mkdir -p /opt/docling/{docs,db,logs}
cd /opt/docling

echo "🐍 Criando ambiente virtual Python..."
sudo python3 -m venv /opt/docling/venv

echo "✅ Ativando ambiente virtual..."
source /opt/docling/venv/bin/activate

echo "⬇️ Instalando pip e setuptools atualizados..."
pip install --upgrade pip setuptools wheel

echo "⬇️ Instalando Docling diretamente do repositório oficial..."
pip install git+https://github.com/docling-ai/docling.git

echo "🧠 Instalando Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

echo "🔁 Criando serviço systemd para ollama..."
sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=root
Group=root
Restart=always
RestartSec=3
Environment="PATH=/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ollama.service

echo "⬇️ Baixando modelo llama3:8b (aguarde, pode levar vários minutos)..."
ollama pull llama3:8b

echo "✅ Criando arquivo de configuração padrão: /opt/docling/docling.yaml"
cat <<CONFIG > /opt/docling/docling.yaml
embedding:
  provider: ollama
  model: llama3:8b

vector_store:
  type: chroma
  path: ./db

ingestion:
  chunk_size: 500
  chunk_overlap: 50

ocr:
  enabled: true
  lang: por
CONFIG

echo "🎉 Instalação concluída!"
echo "📂 Coloque seus PDFs em: /opt/docling/docs"
echo "📌 Para indexar: source /opt/docling/venv/bin/activate && docling ingest /opt/docling/docs"
echo "🧠 Para consultar: docling chat"
