#!/bin/bash

set -e

REPO_URL="https://github.com/veliertunc/beaglebone-overlaygen.git"
CLONE_DIR="beaglebone-overlaygen"

# 📦 Install dependencies
echo "📦 Installing dependencies..."
sudo apt-get update
sudo apt-get install -y jq device-tree-compiler git

# 🧬 Clone the repo
echo "📥 Cloning overlaygen repo..."
if [ ! -d "$CLONE_DIR" ]; then
  git clone "$REPO_URL"
else
  echo "⚠️ Repo already exists. Skipping clone."
fi

cd "$CLONE_DIR"

# 🔧 Make scripts executable
chmod +x overlaygen.sh

# 🚀 Run the tool
echo ""
echo "🚀 Launching overlay generator..."
./overlaygen.sh
