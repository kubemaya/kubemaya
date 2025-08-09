import os
from nicegui import ui

DEST_APPS="/tmp/apps/" if os.environ["DEST_APPS"]==None else os.environ["DEST_APPS"]

def openApp(e):
    ui.navigate.to('/'+e.sender.text,new_tab=True)
    #ui.notify(e.sender.text)

@ui.refreshable
def showApps():
    apps = os.listdir(DEST_APPS)
    for app in apps:
        ui.button(app, on_click=openApp,color="standard")
    if len(apps) == 0:
        ui.label("0 Applications available")