#!/bin/bash
clear
sleep 1 && curl -s https://raw.githubusercontent.com/pacta3abp/logo/main/logo.sh | bash && sleep 1
rm -rf logo.sh
sudo apt update -y
sudo apt upgrade -y
BLUE='\033[1;34m'
NC='\033[0m'

function show() {
    echo -e "${BLUE}$1${NC}"
}

if ! command -v curl &> /dev/null
then
    show "curl not found. Installing curl..."
    sudo apt update && sudo apt install -y curl
else
    show "curl is already installed."
fi
echo

if ! command -v docker &> /dev/null
then
    show "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
else
    show "Docker is already installed."
fi
echo

mkdir -p tora && cd tora

cat <<EOF > docker-compose.yml
services:
  confirm:
    image: oraprotocol/tora:confirm
    container_name: ora-tora
    depends_on:
      - redis
      - openlm
    command: 
      - "--confirm"
    env_file:
      - .env
    environment:
      REDIS_HOST: 'redis'
      REDIS_PORT: 6379
      CONFIRM_MODEL_SERVER_13: 'http://openlm:5000/'
    networks:
      - private_network
  redis:
    image: oraprotocol/redis:latest
    container_name: ora-redis
    restart: always
    networks:
      - private_network
  openlm:
    image: oraprotocol/openlm:latest
    container_name: ora-openlm
    restart: always
    networks:
      - private_network
  diun:
    image: crazymax/diun:latest
    container_name: diun
    command: serve
    volumes:
      - "./data:/data"
      - "/var/run/docker.sock:/var/run/docker.sock"
    environment:
      - "TZ=Asia/Shanghai"
      - "LOG_LEVEL=info"
      - "LOG_JSON=false"
      - "DIUN_WATCH_WORKERS=5"
      - "DIUN_WATCH_JITTER=30"
      - "DIUN_WATCH_SCHEDULE=0 0 * * *"
      - "DIUN_PROVIDERS_DOCKER=true"
      - "DIUN_PROVIDERS_DOCKER_WATCHBYDEFAULT=true"
    restart: always

networks:
  private_network:
    driver: bridge
EOF

clear
sleep 1 && curl -s https://raw.githubusercontent.com/pacta3abp/logo/main/logo.sh | bash && sleep 1
rm -rf logo.sh

echo
read -p "Enter your private key: " PRIV_KEY
read -p "Enter your WS URL for Ethereum Mainnet: " MAINNET_WSS
read -p "Enter your HTTP URL for Ethereum Mainnet: " MAINNET_HTTP
read -p "Enter your WS URL for Sepolia Ethereum: " SEPOLIA_WSS
read -p "Enter your HTTP URL for Sepolia Ethereum: " SEPOLIA_HTTP

cat <<EOF > .env
############### Sensitive config ###############

PRIV_KEY="$PRIV_KEY"

############### General config ###############

TORA_ENV=production

MAINNET_WSS="$MAINNET_WSS"
MAINNET_HTTP="$MAINNET_HTTP"
SEPOLIA_WSS="$SEPOLIA_WSS"
SEPOLIA_HTTP="$SEPOLIA_HTTP"

REDIS_TTL=86400000

############### App specific config ###############

CONFIRM_CHAINS='["sepolia"]'
CONFIRM_MODELS='[13]'

CONFIRM_USE_CROSSCHECK=true
CONFIRM_CC_POLLING_INTERVAL=3000
CONFIRM_CC_BATCH_BLOCKS_COUNT=300

CONFIRM_TASK_TTL=2592000000
CONFIRM_TASK_DONE_TTL=2592000000
CONFIRM_CC_TTL=2592000000
EOF

sudo sysctl vm.overcommit_memory=1
echo
show "Starting Docker containers using docker-compose(may take 5-10 mins)..."
echo
sudo docker compose up -d
sudo docker compose logs -f
