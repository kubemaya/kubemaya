K3S_VERSION=v1.32.3%2Bk3s1
ZOT_VERSION=v2.1.2
HOTSPOT_NAME="MAYABOX"
HOTSPOT_ADDRESS="192.168.0.100/24"
HOTSPOT_GATEWAY="192.168.0.1"
NETWORK_INTERFACE="wlan0"
HOTSPOT_INSTALL="y"
OVERWRITE_YAML=n
OVERWRITE_DOCKERFILE=n

if [ -z "$K3S_ARCH" ]; then
    export K3S_ARCH=arm64
fi

function get_interface_ip_address(){
  interfaces=$(ls /sys/class/net | head -4)
  interface=$(gum choose $interfaces)
  echo "Selected interface $interface"

  ip addr show $interface | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
}

function createDockerfile(){
  rm apps/$1/src/Dockerfile
echo '
FROM python:3-alpine
WORKDIR /app
COPY requirements.txt .
RUN apk update
RUN apk add build-base gcc python3-dev musl-dev linux-headers
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["ash", "-c", "python index.py"]' > apps/$1/src/Dockerfile
}

function error_alert(){
  echo "Error detected, process stopped"
  exit 1
}

function build-mayaui(){
  echo "Packaging kubemaya"
  export OVERWRITE_YAML=yes
  export OVERWRITE_DOCKERFILE=yes
  package kubemaya mayaui v1 $K3S_ARCH
  mv package/mayaui.tgz .
}

function create-app(){
APP=$1
DEST=apps/$APP/src
mkdir -p apps/$APP/src
echo "FROM python:3-alpine
WORKDIR /app
COPY requirements.txt .
RUN apk update
RUN apk add build-base gcc python3-dev musl-dev linux-headers
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["ash", "-c", "python index.py"] " > $DEST/Dockerfile

echo "from flask import Flask, request
from flask import jsonify

app = Flask(__name__)

@app.route(\"/_health\", methods=[\"GET\"])
def getHealth():
    data = {\"response\":\"OK\"}
    return jsonify(data)

@app.route(\"/\", methods=[\"GET\"])
def index():
    data = {\"response\":\"It works\"}
    return jsonify(data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)" > $DEST/index.py

echo "flask
requests" > $DEST/requirements.txt

echo "Created $APP in apps/$APP directory"
}  

function package(){
    DOCKER_USER=$1
    IMAGE_NAME=$2
    IMAGE_TAG=$3
    PLATFORM=$4
    DEST=package/$IMAGE_NAME
    echo "building for $PLATFORM"
    mkdir -p $DEST
    if [[ "$OVERWRITE_DOCKERFILE" == *"y"* ]]; then
      echo "Overwriting with a custom file Dockerfile"
    else
      echo "Creating Dockerfile"
      createDockerfile $IMAGE_NAME
    fi
    cd apps/$IMAGE_NAME/src
    docker build  -t $DOCKER_USER/$IMAGE_NAME:$IMAGE_TAG . --platform linux/$PLATFORM
    echo $(pwd)
    docker save $DOCKER_USER/$IMAGE_NAME:$IMAGE_TAG > ../../../$DEST/$IMAGE_NAME.tar
    if [[ "$OVERWRITE_YAML" == *"y"* ]]; then
      echo "Overwriting app.yaml with a custom file"
      cp ../yaml/app.yaml ../../../$DEST/
    else
      kubectl create deployment $IMAGE_NAME --image=$DOCKER_USER/$IMAGE_NAME:$IMAGE_TAG --dry-run -o yaml > ../../../$DEST/app.yaml
    fi
    cd ../../../
    echo $(pwd)
    cd package/$IMAGE_NAME
    tar -czvf $IMAGE_NAME.tgz *
    mv $IMAGE_NAME.tgz ../
    cd ../../
    echo $(pwd)
    echo "Package package/$IMAGE_NAME.tgz created"
}

function write_st(){
  echo '{{ Color "99" "0" " <<< '$1' >>>\n " }}'| gum format -t template
}

function write_ft(){
  gum format -- "$@"
}

function write_line(){
  echo '{{ Color "10" "0" " '$1'\n " }}'| gum format -t template
}

function write_emo(){
  echo $1 | gum format -t emoji
}

function write_box(){
  gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        "$@"
}

function read_var(){
  export $1=$(gum input --value=$2)
}

function spinner(){
  gum spin --spinner dot --show-error --title "$1" $2
}

function dialog_yn(){
  gum confirm && export $1="yes" || export $1="no"
}

function gum-install(){
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
  sudo apt update && sudo apt install gum  
}

function set-wifi(){
nmcli con add con-name $HOTSPOT_NAME ifname $NETWORK_INTERFACE type wifi ssid $HOTSPOT_NAME mode ap
nmcli con modify $HOTSPOT_NAME connection.autoconnect yes
nmcli con modify $HOTSPOT_NAME ipv4.method shared ipv4.address $HOTSPOT_ADDRESS ipv4.gateway $HOTSPOT_GATEWAY
nmcli con modify $HOTSPOT_NAME ipv6.method disabled
nmcli con up $HOTSPOT_NAME
}

function install-k8s-packages(){
  sudo export DEBIAN_FRONTEND=noninteractive
  sudo apt-get install -y dialog nano gpg curl iptables-persistent skopeo autofs
  sudo systemctl enable ssh
}

function install-dep(){
  echo "Installing Gum first"
  sudo apt-get update
  sudo apt-get install -y gpg git curl
  gum-install
  sleep 5
  spinner "Installing missing dependencies..." "sudo /bin/bash /opt/k3s/scripts/kubemaya.sh install-k8s-packages"
}

function clean(){
  echo "starting cleanup"
  rm *.tgz
  rm -R images
  rm k3s-airgap-images-$K3S_ARCH.tar
  #rm zot-linux-$K3S_ARCH
  rm install.sh
  if [[ "$K3S_ARCH" == *"arm"* ]]; then
    rm k3s-$K3S_ARCH
  else
    rm k3s
  fi
  rm save-images.sh
  rm images/*
  rm -R package
  echo "cleanup done"
}

function gen-installer(){
  if docker ps -a; then
    echo "Docker running."
  else
    echo "Docker is not working. Please start the service."
    exit 1
  fi
  rm install.sh k3s-$K3S_ARCH k3s-airgap-images-$K3S_ARCH.tar
  save-images
  build-mayaui
  #echo "Downloading Zot Registry"
  #curl -#LO https://github.com/project-zot/zot/releases/download/$ZOT_VERSION/zot-linux-$K3S_ARCH
  echo "Downloading K3s binary"
  if [[ "$K3S_ARCH" == *"arm"* ]]; then
    curl -#LO https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s-$K3S_ARCH || error_alert
  else
    curl -#LO https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s || error_alert
  fi
  echo  "Download K3s install.sh script"
  curl -#L  https://get.k3s.io -o install.sh
  echo "Downloading airgap images"
  curl -#LO https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s-airgap-images-$K3S_ARCH.tar || error_alert
  echo "setting permissions to k3s and install.sh"
  if [[ "$K3S_ARCH" == *"arm"* ]]; then
    chmod +x k3s-$K3S_ARCH
  else
    chmod +x k3s
  fi
  chmod +x install.sh
  echo "Packing installer components"
  tar --exclude='apps' --exclude='package' --exclude='releases' -vzcf k3s_airgapped_installer.tgz $(ls)
  sleep 5
  echo "Done"
  echo "Running cleanup"
  rm k3s-airgap-images-$K3S_ARCH.tar
  if [[ "$K3S_ARCH" == *"arm"* ]]; then
    rm k3s-$K3S_ARCH
  else
    rm k3s
  fi
  rm save-images.sh
  #rm zot-linux-$K3S_ARCH
  rm -R images
  rm install.sh
  echo "Now copy the k3s_airgapped_installer.tgz to your device :)"
  exit 0
}

function scp_device(){
  IP_ADDRESS=$1
  USER=$2
  echo "Copy files to device ${IP_ADDRESS}"
  scp k3s_airgapped_installer.tgz $USER@${IP_ADDRESS}:/home/$USER
  exit 0
}

function update_installer_file(){
  IP_ADDRESS=$1
  echo "Copy installer.sh to device ${IP_ADDRESS}"
  scp installer.sh deb/* developer@${IP_ADDRESS}:/home/developer
  #scp deb/* developer@${IP_ADDRESS}:/home/developer
  echo "Done"
  exit 0
}

function clean-k3s-installation(){
  sudo rm -R /opt/k3s
  sudo rm -R /var/lib/rancher/
  exit 0
}

function zot-install(){
  echo "Pre Configuring Zot Registry"
  sudo mv /opt/k3s/zot-linux-$K3S_ARCH /usr/bin/zot
  sudo chmod +x /usr/bin/zot
  sudo chown root:root /usr/bin/zot
  cd /opt/k3s
  echo "Done"
  configure-zot
}

function configure-executor(){
echo "Configuring Executor"
sudo mkdir -p /app/shell
echo "echo 'Running KubeMaya Executor for the First Time'" > /app/shell/script.sh
sudo echo '
[Unit]
Description=KubeMaya Executor

[Service]
Type=simple
ExecStart=/bin/bash -c "while true; do [ -e '/app/shell/script.sh' ] && (echo 'KubeMaya Executor: Running script.sh';cp /app/shell/script.sh /app/shell/run-script.sh;rm /app/shell/script.sh;/bin/bash /app/shell/run-script.sh) || echo 'KubeMaya Executor: Nothing to run';sleep 10; done"
Restart=on-failure

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/km-executor.service

sudo systemctl daemon-reload
sudo systemctl enable km-executor
sudo systemctl start km-executor
}


function configure-zot(){
echo "Configuring Zot"
sudo mkdir /etc/zot
sudo echo '
{
    "distSpecVersion": "1.1.1",
    "storage": {
        "rootDirectory": "/tmp/zot"
    },
    "http": {
        "address": "127.0.0.1",
        "port": "8080"
    },
    "log": {
        "level": "debug"
    }
}' > config.json
sudo mv ./config.json /etc/zot/config.json

sudo echo '
[Unit]
Description=OCI Distribution Registry
Documentation=https://zotregistry.dev/
After=network.target auditd.service local-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/zot serve /etc/zot/config.json
Restart=on-failure
User=zot
Group=zot
LimitNOFILE=500000
MemoryHigh=30G
MemoryMax=32G

[Install]
WantedBy=multi-user.target' > zot.service
sudo mv ./zot.service /etc/systemd/system/zot.service

sudo adduser --no-create-home --disabled-password --gecos --disabled-login zot

sudo mkdir -p /data/zot
sudo chown -R zot:zot /data/zot

sudo mkdir -p /var/log/zot
sudo chown -R zot:zot /var/log/zot

sudo chown -R root:root /etc/zot/

sudo systemctl daemon-reload
sudo systemctl enable zot
sudo systemctl start zot

sudo -u zot zot verify /etc/zot/config.json
sudo systemctl status zot
echo "Done"

}

function set-network(){
  echo ">>>> Setting Network"
  sudo ip link add dummy0 type dummy
  sudo ip link set dummy0 up
  sudo ip addr add 192.168.1.3/24 dev dummy0
  sudo ip route add default via 192.168.1.1 dev dummy0 metric 1000
  nmcli connection add type dummy ifname dummy0 ipv4.method manual ipv4.addresses 192.168.1.3/24 ipv6.method manual ipv6.addresses 2001:db8:2::1/64

  echo ">>>> Done"
  echo "Showing interfaces Info"
  ifconfig
  echo "Done"
}

function set-flags(){
  sudo sed -e 's/$/ cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory/' -i /boot/firmware/cmdline.txt
  sudo reboot
}

function save-images(){
  echo $(pwd)
  mkdir images
  rm save-images.sh
echo "function save-image(){
  TAR_NAME=\$1
  IMG=\$2
  ARCH=\$3
  docker pull \$IMG --platform \$ARCH
  docker save \$IMG > images/\$TAR_NAME.tar
}" >> save-images.sh

  cat scripts/containers | awk '{print "save-image "$1,$2,$3;}' >> save-images.sh
  sleep 2s
  echo "Downloading container images"
  /bin/bash save-images.sh
  echo $(ls images/)
}

function install-mayaui(){
  sudo mkdir /opt/k3s/mayaui
  sudo tar -xzvf /opt/k3s/mayaui.tgz -C /opt/k3s/mayaui
  sudo mv /opt/k3s/mayaui/mayaui.tar /var/lib/rancher/k3s/agent/images
  sudo mv /opt/k3s/mayaui/app.yaml /var/lib/rancher/k3s/server/manifests
  sudo cp /opt/k3s/scripts/default/*.yaml /var/lib/rancher/k3s/server/manifests
}

function k3s-install(){
  write_box 'Welcome to Kubemaya' 'Running airgapped envs on edge'
  write_st "Fill the next information to prepare your device"
  write_line "Do you want to configure your device with a Wifi Hotspot(y/n):"
  read_var HOTSPOT_INSTALL "n"
  if [[ "$HOTSPOT_INSTALL" == *"y"* ]]; then
    write_line "Choose the Wifi Network Interface:"
    interfaces=$(ls /sys/class/net | head -4)
    interface=$(gum choose $interfaces)
    export NETWORK_INTERFACE=$interface
    write_line $NETWORK_INTERFACE
    write_line "Input the Hotspot Network Name to create:"
    read_var HOTSPOT_NAME $HOTSPOT_NAME
    write_line $HOTSPOT_NAME
    write_line "Input the Hotspot address:"
    read_var HOTSPOT_ADDRESS $HOTSPOT_ADDRESS
    write_line $HOTSPOT_ADDRESS
    write_line "Input the Hotspot gateway:"
    read_var HOTSPOT_GATEWAY $HOTSPOT_GATEWAY
    write_line $HOTSPOT_GATEWAY
#    write_line "Input the Hotspot INTERFACE:"
#    read_var NETWORK_INTERFACE $NETWORK_INTERFACE
#    write_line $NETWORK_INTERFACE
  else
    write_st "When Hotspot skipped, be sure to have a network configuration"
  fi
  #write_line "Do you want to install a local Zot container registry (y/n)"
  #read_var ZOT_INSTALL "n"
  write_line "Extra parameters for K3s"
  read_var K3S_EXTRA_PARS "--disable=metrics-server"

  #set-network
  if [[ "$HOTSPOT_INSTALL" == *"y"* ]]; then
    spinner "Setting Wifi" "/bin/bash ./scripts/kubemaya.sh set-wifi"
    write_st "Wifi Configured"
    spinner "Waiting for wifi connection" "sleep 10"
    write_st "Wifi Ready"
    write_st "Preparing installation"
  fi
  #if [[ "$ZOT_INSTALL" == *"y"* ]]; then
  #  write_st "Zot will be installed"
  #  zot-install
  #else
  #  echo "Zot installation skipped"
  #fi
  spinner "Setting KubeMaya Executor" "/bin/bash ./scripts/kubemaya.sh configure-executor"
  write_st "Installing K3s"
  cd /opt/k3s
  sudo mkdir -p /var/lib/rancher/k3s/agent/images/ 
  sudo mkdir -p /usr/local/bin/
  if [[ "$K3S_ARCH" == *"arm"* ]]; then
    sudo mv k3s-$K3S_ARCH /usr/local/bin/k3s
  else
    sudo mv k3s /usr/local/bin
  fi
  sudo mv k3s-airgap-images-$K3S_ARCH.tar /var/lib/rancher/k3s/agent/images/
  sudo mv images/*.tar /var/lib/rancher/k3s/agent/images/
  sudo chmod +x /usr/local/bin/k3s
  sudo chmod +x /opt/k3s/install.sh
  write_st "Ready to install"
## For agents
##  INSTALL_K3S_SKIP_DOWNLOAD=true K3S_URL=https://$MASTER_NODE_IP_OR_FQDN:6443 K3S_TOKEN=$TOKEN_TO_USE ./install.sh
  write_st "Installing K3s"
  sudo INSTALL_K3S_SKIP_DOWNLOAD=true K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="$K3S_EXTRA_PARS" ./install.sh
  write_emo "K3s installation done - check output for error :smile:"
  write_st "Installing MayaUI"
  install-mayaui
  
#echo "Load Container Images"
#skopeo copy --format=oci docker-archive:nginx.tar docker://127.0.0.1:8080/nginx2 --dest-tls-verify=false
}

"$@"