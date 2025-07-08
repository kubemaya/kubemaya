# kubemaya
Airgapped script for K3s running on Edge

## Creating the k3s installer (Developer Environment)
In your Developer Machine do the next:
1. Clone the repository
```
git clone https://github.com/sergioarmgpl/kubemaya.git
```

2. Change to the airgap directory
```
cd kubemaya
```
3. Prepare a fresh environment
```
export PATH=$PATH:$(pwd)/scripts
chmod +x scripts/kubemaya.sh
/bin/bash kubemaya.sh clean
```
Note: To override the architecture use the following command:
```
K3S_ARCH=amd64 /bin/bash kubemaya.sh clean
```   
4. Set the container files that you to include in your installer by setting the content in the images for example:   
```
busybox 1.37.0 linux/arm64/v8
redis 8.0.0-alpine3.21 linux/arm64/v8
nginx 1.17.5-alpine linux/arm64/v8
```   
**Note:** The format used in this file is ```image version architecture```  

5. Start you docker service and be sure of having the docker cli   

6. Generate the tgz file which contains all the images to run offline and the installer   
```
/bin/bash kubemaya.sh gen-installer
```
**Note:** To override to a different architecture than arm64, use the variable K3S_ARCH=<amd64,etc>. Also, you have to start docker before run it.   
```
K3S_ARCH=SOME_VALUE /bin/bash kubemaya.sh gen-installer
```
7. Copy the k3s_airgapped_installer.tgz to a USB storage

## Setting up K3s with the installer (RPI with Rasbian Bookworm)
In your edge device run the following steps:
1. Set your WLAN location before start (sudo raspi-config Localisation Options > WLAN Country)
2. Set a temporary WIFI Connection with nmtui
```
sudo mount /dev/sda1 /mnt
```
3. Copy the file to the edge device (Mount a USB Device)
```
cp /mnt/k3s_airgapped_installer.tgz .
```
4. Or copy the .tgz using scp using ssh
```
/bin/bash kubemaya.sh scp_device <IP_ADDRESS> <USER>
```
5. Untar the file in /opt/k3s:
```
sudo mkdir -p /opt/k3s
sudo tar -xzvf k3s_airgapped_installer.tgz -C /opt/k3s
```
6. Install missing dependencies (Tested in Rasbian minimal)
```
sudo /bin/bash /opt/k3s/scripts/kubemaya.sh install-dep
```
7. Set the flags to use containers in your device by running(Raspberry only):
```
/bin/bash /opt/k3s/scripts/kubemaya.sh set-flags
```
**Note:** This restarts your device, also for Debian you have to set the following flag systemd.unified_cgroup_hierarchy=1 in the variable GRUB_CMDLINE_LINUX_DEFAULT inside the file /etc/default/grub and restart your device.  
8. Disable your current wifi-connection if set (nmtui in Raspbian)  
9. Change to the installer path
```
cd /opt/k3s
```
10. Install K3s running:
```
sudo /bin/bash scripts/kubemaya.sh k3s-install
```   
**Note:** To override to a different architecture than arm64, use the variable K3S_ARCH=<amd64,etc>.
```
sudo K3S_ARCH=SOME_VALUE /bin/bash scripts/kubemaya.sh k3s-install
```   

## Cleaning previous installation
To clean a previous installation run the following commands
1. To uninstall K3s run:
```
k3s-uninstall.sh
```   
2. Delete the /opt/k3s directory:
```
rm -R /opt/k3s
```   

## /var/lib/rancher/k3s/server/manifests
## Testing your installation
sudo ctr containers list 
#skopeo

Run the following commands in the device to install nginx:
```
kubectl create deploy nginx --image=nginx:1.17.5-alpine
kubectl expose deploy nginx --port=80
kubectl create ingress nginx --rule=/=nginx:80
```
Access the nginx in http://192.168.0.100 in the device that
is connected to the new MAYABOX Network



## Create application to deploy
***Option 1***
1. Clone the demo-application folder
2. Rename the folder   
***Option 2***
1. Create an application by running:
```
/bin/bash scripts/kubemaya.sh create-app demo-application
```   
2. Build and package the app with the following command:
```
/bin/bash scripts/kubemaya.sh package sergioarmgpl demo-application v1 amd64
```   
***To overriding the Dockefile and YAML***
To override the Dockefile with your own set the variable:
```
export OVERWRITE_DOCKERFILE=yes
```   
To override the YAML with your own set the variable:
```
export OVERWRITE_YAML=yes
```   
Then run the command.