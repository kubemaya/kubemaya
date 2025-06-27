K3S_VERSION=v1.32.3%2Bk3s1
ZOT_VERSION=v2.1.2
K3S_ARCH=arm64

function set-wifi(){
nmcli con add con-name MAYABOX ifname wlan0 type wifi ssid MAYABOX mode ap
nmcli con modify MAYABOX connection.autoconnect yes
nmcli con modify MAYABOX ipv4.method shared ipv4.address 192.168.0.100/24 ipv4.gateway 192.168.0.1
nmcli con modify MAYABOX ipv6.method disabled
nmcli con up MAYABOX
}

function install-dep(){
  sudo apt-get update
  sudo apt-get install -y dialog iptables-persistent skopeo
}

function clean(){
  rm k3s_airgapped_installer.tgz
  rm -R images
  rm k3s-airgap-images-$K3S_ARCH.tar
  rm zot-linux-$K3S_ARCH
  rm install.sh
  rm k3s-$K3S_ARCH
  rm save-images.sh
  rm images/*
  echo "cleanup done"
}

function gen-installer(){
  rm install.sh k3s-$K3S_ARCH k3s-airgap-images-$K3S_ARCH.tar
  echo "Downloading Zot Registry"
  curl -#LO https://github.com/project-zot/zot/releases/download/$ZOT_VERSION/zot-linux-$K3S_ARCH
  echo "Downloading K3s binary"
  curl -#LO https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s-$K3S_ARCH
  echo  "Download K3s install.sh script"
  curl -#L  https://get.k3s.io -o install.sh
  echo "Downloading airgap images"
  curl -#LO https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s-airgap-images-$K3S_ARCH.tar
  echo "setting permissions to k3s and install.sh"
  chmod +x k3s-$K3S_ARCH
  chmod +x install.sh
  echo "downloading images for zot"
  save-images
  echo "Packing installer components"
  tar -vzcf k3s_airgapped_installer.tgz $(ls)
  sleep 5
  echo "Done"
  echo "Running cleanup"
  rm k3s-airgap-images-$K3S_ARCH.tar
  rm k3s-$K3S_ARCH
  rm save-images.sh
  rm zot-linux-$K3S_ARCH
  rm -R images
  rm install.sh
  echo "Now copy the k3s_airgapped_installer.tgz to your device :)"
  exit 0
}

function scp_device(){
  IP_ADDRESS=$1
  echo "Copy files to device ${IP_ADDRESS}"
  scp installer.sh deb/*  k3s_airgapped_installer.tgz developer@${IP_ADDRESS}:/home/developer
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

function pre-install(){
  echo "Pre Configuring Zot Registry"
  sudo mv /opt/k3s/zot-linux-$K3S_ARCH /usr/bin/zot
  sudo chmod +x /usr/bin/zot
  sudo chown root:root /usr/bin/zot
  cd /opt/k3s
  echo "Done"
  configure-zot
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
  IMG=\$1
  VERSION=\$2
  ARCH=\$3
  docker pull \$IMG:\$VERSION --platform \$ARCH
  docker save \$IMG:\$VERSION > images/\$IMG.tar
}" >> save-images.sh

  cat containers | awk '{print "save-image "$1,$2,$3;}' >> save-images.sh
  sleep 2s
  echo "Downloading container images"
  /bin/bash save-images.sh
  echo $(ls images/)
}



function k3s-install(){
  pre-install
  echo ">>>> Installing K3s"
  #set-network
  set-wifi
  sleep 10
  cd /opt/k3s
  echo "In folder "$(pwd)
  sudo mkdir -p /var/lib/rancher/k3s/agent/images/ 
  sudo mkdir -p /usr/local/bin/
  sudo mv k3s-$K3S_ARCH /usr/local/bin/k3s
  sudo mv k3s-airgap-images-$K3S_ARCH.tar /var/lib/rancher/k3s/agent/images/
  sudo mv images/*.tar /var/lib/rancher/k3s/agent/images/


  sudo chmod +x /usr/local/bin/k3s
  sudo chmod +x /opt/k3s/install.sh

## For agents
##  INSTALL_K3S_SKIP_DOWNLOAD=true K3S_URL=https://$MASTER_NODE_IP_OR_FQDN:6443 K3S_TOKEN=$TOKEN_TO_USE ./install.sh
  sudo INSTALL_K3S_SKIP_DOWNLOAD=true K3S_KUBECONFIG_MODE="644"  ./install.sh


#echo "Load Container Images"
#skopeo copy --format=oci docker-archive:nginx.tar docker://127.0.0.1:8080/nginx2 --dest-tls-verify=false

}

##call the proper function
#$1 $2 $3
"$@"