function get_interfaces(){
    interfaces=$(ls /app/sys/class/net | head -4)
    rm /app/interfaces
    touch /app/interfaces
    for interface in ${interfaces[@]}; do
        ip_addr=$(ip addr show $interface | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        echo "${interface},${ip_addr}"
        echo "${interface},${ip_addr}" >> /app/interfaces
    done;
}

"$@"