import os
from nicegui import ui

DEST_APPS="/tmp/apps"
HOST="http://192.168.0.100"
@ui.refreshable
def showApps():
    apps = os.listdir(DEST_APPS)
    for app in apps:
        ui.button(app, on_click=lambda: ui.navigate.to(HOST+'/'+app,new_tab=True),color="standard")
    print(len(apps))
    if len(apps) == 0:
        ui.label("0 Applications available")
