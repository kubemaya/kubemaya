from kubernetes import client, config
from nicegui import ui

def getAllPods():
    # Configs can be set in Configuration class directly or using helper utility
    config.load_kube_config()

    v1 = client.AppsV1Api()
    print("Listing pods with their IPs:")
    ret = v1.list_deployment_for_all_namespaces(watch=False)
    rows = []
    for i in ret.items:
        #print("%s\t%s\t%s" % (i.metadata.namespace,i.metadata.name, i.status.phase))
        rows.append({'namespace': i.metadata.namespace, 'name': i.metadata.name, "status":"Running" if i.status.ready_replicas==i.status.replicas else "UnStable" })
    columns = [
        {'name': 'namespace', 'label': 'Namespace', 'field': 'namespace', 'required': True, 'align': 'left'},
        {'name': 'name', 'label': 'Name', 'field': 'name', 'sortable': True},
        {'status': 'status', 'label': 'Status', 'field': 'status', 'sortable': True},

    ]
    ui.table(columns=columns,
             rows=rows, 
             row_key='name',
             on_select=lambda e: ui.notify(f'selected: {e.selection}'))
