#change into python https://blog.nashtechglobal.com/how-to-create-service-using-kubernetes-python-client/
#https://github.com/kubernetes-client/python/tree/master/examples
from kubernetes import client, config
from nicegui import events,ui
from kubernetes.client.rest import ApiException
import datetime

def restart_deployment(v1_apps, deployment, namespace):
    now = datetime.datetime.utcnow()
    now = str(now.isoformat("T") + "Z")
    body = {
        'spec': {
            'template':{
                'metadata': {
                    'annotations': {
                        'kubectl.kubernetes.io/restartedAt': now
                    }
                }
            }
        }
    }
    try:
        v1_apps.patch_namespaced_deployment(deployment, namespace, body, pretty='true')
    except ApiException as e:
        print("Exception when calling AppsV1Api->read_namespaced_deployment_status: %s\n" % e)

@ui.refreshable
def getAllDeployments():
    # Configs can be set in Configuration class directly or using helper utility
    #config.load_kube_config()
    #config.load_kube_config()
    try:
        config.load_incluster_config()
    except config.ConfigException:
        try:
            config.load_kube_config()
        except config.ConfigException:
            raise Exception("Could not configure kubernetes client")
    
    v1 = client.AppsV1Api()
    ret = v1.list_deployment_for_all_namespaces(watch=False)
    rows = []
    for i in ret.items:
        #print("%s\t%s\t%s" % (i.metadata.namespace,i.metadata.name, i.status.phase))
        rows.append({'namespace': i.metadata.namespace, 'name': i.metadata.name, "status":"Running" if i.status.ready_replicas==i.status.replicas else "UnStable" })
    columns = [
        {'name': 'namespace', 'label': 'Namespace', 'field': 'namespace', 'required': True, 'align': 'left'},
        {'name': 'name', 'label': 'Name', 'field': 'name', 'sortable': True},
        {'name': 'status', 'label': 'Status', 'field': 'status', 'sortable': True},
    ]

    def restart(e: events.GenericEventArguments) -> None:
        ui.notify(f'Restart Deployment {e.args["name"]} in {e.args["namespace"]}')
        restart_deployment(v1, e.args["name"], e.args["namespace"])
        #table.update()

    table = ui.table(columns=columns, rows=rows, row_key='name') #.classes('w-80')
    table.add_slot('header', r'''
        <q-tr :props="props">
            <q-th auto-width />
            <q-th v-for="col in props.cols" :key="col.name" :props="props">
                {{ col.label }}
            </q-th>
        </q-tr>
    ''')
    table.add_slot('body', r'''
        <q-tr :props="props">
            <q-td auto-width >
                <q-btn size="sm" color="warning" dense label="Restart"
                    @click="() => $parent.$emit('restart', props.row)"
                />
            </q-td>
            <q-td key="namespace" :props="props">
                {{ props.row.namespace }}

            </q-td>
            <q-td key="name" :props="props">
                {{ props.row.name }}

            </q-td>
            <q-td key="status" :props="props">
                {{ props.row.status }}

            </q-td>
        </q-tr>
    ''')
    table.on('restart', restart)

#    def handle_click():
#        table.update()

    #ui.button('Refresh Deployments', on_click=getAllDeployments)