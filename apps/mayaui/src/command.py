from nicegui import ui
import subprocess

def runcmd(editor,log):
    log.clear()
    lines = editor.value.splitlines()
    for line in lines:
        result = subprocess.check_output(line, shell=True, text=True)
        log.push(result)
        log.push("------------------")

def cli():
    with ui.row():
        ui.html('<strong>Run your script</strong>')
        editor = ui.codemirror('kubectl get nodes', language='Shell').classes('h-32')
        log = ui.log(max_lines=100).classes('w-full h-40')
        ui.button('Run', on_click=lambda: runcmd(editor,log))
        


  
