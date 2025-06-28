from nicegui import events, ui
import tarfile
import os
import time
import subprocess

DEST_UPLOAD="/tmp/upload/"
DEST_APPS="/tmp/apps/"
DEST_IMAGE="/tmp/imgs/"

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
                os.system("/bin/bash deploy.sh deploy_app "+filename)
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