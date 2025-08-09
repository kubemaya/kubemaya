from nicegui import events, ui
import tarfile
import os
import time
import subprocess

DEST_UPLOAD="/tmp/upload/" if os.environ["DEST_UPLOAD"]==None else os.environ["DEST_UPLOAD"]
DEST_APPS="/tmp/apps/" if os.environ["DEST_APPS"]==None else os.environ["DEST_APPS"]
DEST_IMAGE="/tmp/imgs/" if os.environ["DEST_IMAGE"]==None else os.environ["DEST_IMAGE"]

UPLOAD_RETRIES=3
APP_PORT=80

def extract(filename):
    try:
        os.system("rm -R "+DEST_APPS+filename.replace(".tgz",""))
    except:
        print("App not found to reinstall")
    i = 0
    while i < UPLOAD_RETRIES:
        try:
            with tarfile.open(DEST_UPLOAD+filename, 'r') as tar:
                filename=filename.replace(".tgz","")
                os.mkdir(DEST_APPS+filename)
                tar.extractall(path=DEST_APPS+filename)
                print(filename+" extracted")
                print("/bin/sh deploy.sh deploy_app "+filename+" "+DEST_IMAGE+" "+DEST_APPS+" Uploaded in "+DEST_UPLOAD)
                os.system("/bin/sh deploy.sh deploy_app "+filename+" "+DEST_IMAGE+" "+DEST_APPS)
                return
        except:
            print("Waiting for file or trying again")
            time.sleep(10)
            i+=1

def uploadApp():
    with ui.dialog().props('full-width') as dialog:
        with ui.card():
            content = ui.markdown()

    def handle_upload(e: events.UploadEventArguments):
        data = e.content.read()
        with open(DEST_UPLOAD+e.name, "wb") as binary_file:
            binary_file.write(data)
        print("file written")
        extract(e.name)
        content.set_content("File uploaded Successfully")
        dialog.open()

    ui.upload(on_upload=handle_upload).props('accept=.tgz').classes('max-w-full')