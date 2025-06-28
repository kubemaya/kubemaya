DEST_APPS=/tmp/apps
APP_PORT=80
DEST_IMAGE=/tmp/imgs
function delete(){
    app=$1
    kubectl delete -f $DEST_APPS/$app -n $app
    kubectl delete ns $app
    rm -R $DEST_APPS/$app
}

"$@"