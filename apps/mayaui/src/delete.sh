APP_PORT=80
function delete(){
    app=$1
    DEST_IMAGE=$2
    DEST_APPS=$3
    kubectl delete -f $DEST_APPS/$app -n $app
    kubectl delete ns $app &
    rm -R $DEST_APPS/$app
    rm -R $DEST_IMAGE/$app.tar
}

"$@"