from nicegui import ui
from k8s import getAllDeployments
from upload_app import uploadApp
from menu_app import showApps
from device import shutdown,restart,memory,CPU,disk
from command import cli
import os

def del_app():
    os.system("/bin/sh delete.sh delete "+i.value)
    ui.notify("Deleted Deployment "+i.value,position="top",type="positive")

@ui.page('/login')
def page1():
    ui.label('page1')

@ui.page('/page2', dark=True)
def page2():
    ui.label('page2')

with ui.tabs() as tabs:
    ui.tab('apps', label='Apps', icon='widgets')
    ui.tab('k8s', label='K8s', icon='rocket_launch')
    ui.tab('upload', label='Upload', icon='add_to_home_screen')
    ui.tab('delete', label='Delete', icon='delete')
    ui.tab('device', label='Device', icon='router')
    ui.tab('cmd', label='Commands', icon='code')
    #ui.html("<strong>KUBEMAYA</strong>")

with ui.tab_panels(tabs, value='h').classes('w-full'):
    with ui.tab_panel('apps'):
        #ui.label('Available Apps')
        ui.html('<strong>Available Apps</strong>')
        #ui.markdown('### Available Apps')
        showApps()
    with ui.tab_panel('k8s'):
        ui.html('<strong>Showing all Deployments</strong>')
        getAllDeployments()
    with ui.tab_panel('upload'):
        ui.html('<strong>Upload a new Application</strong>')
        uploadApp()
    with ui.dialog() as dialog, ui.card():
        ui.label('Application deleted')
        ui.button('Close', on_click=dialog.close)
    with ui.tab_panel('delete'):
        ui.html('<strong>Delete</strong>')
        options = ['AutoComplete', 'NiceGUI', 'Awesome']
        i = ui.input(label='App to delete', placeholder='App name', autocomplete=options)
        ui.button("Delete App", on_click=lambda: del_app(),color="deep-orange")

    with ui.tab_panel('device'):
        ui.html('<strong>Device Information</strong>')
        #ui.circular_progress(value=0.0,min=0,max=100)
        memory()
        CPU()
        disk()
        ui.html('<strong>Device Operations</strong>')
        with ui.button_group():
            ui.button("Restart", on_click=lambda: restart(),color="amber")
            ui.button("Shutdown", on_click=lambda: shutdown(), color="purple")
    with ui.tab_panel('cmd'):
        #ui.label('Available Apps')
        #ui.markdown('### Available Apps')
        cli()        

ui.timer(5.0, getAllDeployments.refresh)
ui.timer(5.0, showApps.refresh)
ui.timer(5.0, memory.refresh)
ui.timer(5.0, CPU.refresh)
ui.timer(5.0, disk.refresh)

ui.run(host='0.0.0.0', port=8080, title='KubeMaya')
