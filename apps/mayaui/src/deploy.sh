APP_PORT=8080

function deploy_app(){
    export app=$1
    DEST_IMAGE=$2
    DEST_APPS=$3
    cp $DEST_APPS/$app/*.tar $DEST_IMAGE
    kubectl create ns $app
    kubectl apply -f $DEST_APPS/$app -n $app
    #kubectl rollout status deployment/$app -n $app --timeout=1m
    kubectl expose deployment $app --port=$APP_PORT -n $app

echo "apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-prefix
  namespace: ${app}
spec:
  stripPrefixRegex:
    regex:
    - ^/[^/]+" | kubectl apply -f -

    kubectl create ingress $app \
    --rule=/$app*=$app:$APP_PORT -n $app --class=traefik \
    --annotation traefik.ingress.kubernetes.io/router.middlewares=$app-strip-prefix@kubernetescrd
    echo "app installed"
    exit 0
}

"$@"