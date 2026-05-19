#!/usr/bin/env bash
#
# Cai Node.js 16, Docker, AWS CLI v2 tren may Jenkins (Ubuntu 26.04).
# Chay: sudo bash install-build-tools.sh

set -euo pipefail

UBUNTU_CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
ARCH="$(dpkg --print-architecture)"

log() { echo -e "\n\033[1;32m[+] $*\033[0m"; }

if [[ $EUID -ne 0 ]]; then
    echo "Chay voi sudo: sudo bash $0"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

log "Update apt + cai goi co ban"
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release unzip git

install -m 0755 -d /etc/apt/keyrings

# ---------- Node.js + npm ----------
# Node 16 da EOL nen NodeSource khong build cho Ubuntu moi. Tai binary truc tiep.
NODE_VERSION_FULL="${NODE_VERSION_FULL:-16.20.2}"
case "${ARCH}" in
    amd64) NODE_ARCH="x64" ;;
    arm64) NODE_ARCH="arm64" ;;
    *) echo "Arch khong ho tro cho Node: ${ARCH}"; exit 1 ;;
esac

log "Cai Node.js v${NODE_VERSION_FULL} (linux-${NODE_ARCH}) tu nodejs.org"
NODE_TMP="$(mktemp -d)"
NODE_TARBALL="node-v${NODE_VERSION_FULL}-linux-${NODE_ARCH}.tar.xz"
curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION_FULL}/${NODE_TARBALL}" \
    -o "${NODE_TMP}/node.tar.xz"
tar -xJf "${NODE_TMP}/node.tar.xz" -C /usr/local --strip-components=1 --no-same-owner
rm -rf "${NODE_TMP}"

# Verify ngay - neu fail script se dung o day
command -v node >/dev/null || { echo "Node install FAILED"; exit 1; }
command -v npm  >/dev/null || { echo "npm install FAILED";  exit 1; }
echo "  node: $(node -v)   npm: $(npm -v)"

# ---------- Docker ----------
log "Cai Docker Engine"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
systemctl enable --now docker

# Cho user jenkins chay docker khong can sudo
if id jenkins &>/dev/null; then
    log "Them user 'jenkins' vao group docker"
    usermod -aG docker jenkins
    systemctl restart jenkins || true
fi

# ---------- AWS CLI v2 ----------
log "Cai AWS CLI v2"
case "${ARCH}" in
    amd64) AWS_PKG="awscli-exe-linux-x86_64.zip" ;;
    arm64) AWS_PKG="awscli-exe-linux-aarch64.zip" ;;
    *) echo "Arch khong ho tro: ${ARCH}"; exit 1 ;;
esac
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
curl -fsSL "https://awscli.amazonaws.com/${AWS_PKG}" -o "${TMP}/awscliv2.zip"
unzip -q "${TMP}/awscliv2.zip" -d "${TMP}"
"${TMP}/aws/install" --update

# ---------- Verify ----------
log "Phien ban da cai:"
echo "  node    : $(node -v)"
echo "  npm     : $(npm -v)"
echo "  docker  : $(docker --version)"
echo "  aws     : $(aws --version)"

log "Xong. Cau hinh AWS credentials trong Jenkins (plugin: aws-credentials)."
