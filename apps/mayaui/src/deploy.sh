#change into python https://blog.nashtechglobal.com/how-to-create-service-using-kubernetes-python-client/
#https://github.com/kubernetes-client/python/tree/master/examples
DEST_APPS=/tmp/apps
APP_PORT=80
#DEST_IMAGE=/tmp/imgs
#DEST_IMAGE=/var/lib/rancher/k3s/agent/images/
function deploy_app(){
    app=$1
    DEST_IMAGE=$2
    DEST_APPS=$3
    cp $DEST_APPS/$app/*.tar $DEST_IMAGE
    kubectl create ns $app
    kubectl apply -f $DEST_APPS/$app -n $app
    #kubectl rollout status deployment/$app -n $app --timeout=1m
    kubectl expose deployment $app --port=$APP_PORT -n $app
    kubectl create ingress $app --rule=/$app*=$app:$APP_PORT -n $app
    kubectl create ingress $app \
    --rule=/$app*=$app:$APP_PORT -n $app --class=traefik \
    --annotation traefik.ingress.kubernetes.io/router.entrypoints=web
    echo "app installed"
    exit 0
}

"$@"