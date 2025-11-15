<template>
  <div>
    <h2>Deployments</h2>
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">{{ error }}</div>
    <div v-else>
      <q-table
        :rows="deployments"
        :columns="columns"
        row-key="name"
        flat
        bordered
      >
        <template v-slot:body-cell-actions="props">
          <q-td>
            <q-btn
              color="primary"
              label="Restart"
              size="sm"
              class="q-mr-sm"
              @click="restartDeployment(props.row.namespace, props.row.name)"
            />
            <q-btn
              color="warning"
              label="Pause"
              size="sm"
              class="q-mr-sm"
              @click="pauseDeployment(props.row.namespace, props.row.name)"
            />  
            <q-btn
              color="warning"
              label="Resume"
              size="sm"
              class="q-mr-sm"
              @click="resumeDeployment(props.row.namespace, props.row.name)"
            />                      
            <q-btn
              color="info"
              label="Logs"
              size="sm"
              class="q-mr-sm"
              @click="showLogs(props.row.namespace, props.row.name)"
            />               
            <q-btn
              color="negative"
              label="Delete"
              size="sm"
              @click="deleteNamespace(props.row.namespace)"
            />
          </q-td>
        </template>
      </q-table>
    </div>

    <!-- Logs Modal -->
    <q-dialog v-model="logsModal" persistent>
      <q-card style="min-width: 80vw; min-height: 60vh;">
        <q-card-section>
          <div class="text-h6">Deployment Logs</div>
        </q-card-section>
        
        <q-card-section>
          <q-input
            v-model="selectedPod"
            label="Pod"
            readonly
            filled
            class="q-mb-md"
          />
          <q-input
            v-model="deploymentLogs"
            type="textarea"
            label="Logs"
            readonly
            autogrow
            filled
            style="font-family: 'Courier New', Courier, monospace; min-height: 300px;"
          />
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Close" color="primary" @click="logsModal = false" />
        </q-card-actions>
      </q-card>
    </q-dialog>

  </div>
</template>

<script>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useQuasar } from 'quasar'

export default {
  name: 'DeploymentsLink',
  setup() {
    const $q = useQuasar()
    const deployments = ref([])
    const loading = ref(true)
    const error = ref(null)

    const logsModal = ref(false)
    const deploymentLogs = ref('')
    const selectedPod = ref('')

    let intervalId = null

    const columns = [
      { name: 'namespace', label: 'Namespace', align: 'left', field: 'namespace' },
      { name: 'name', label: 'Name', align: 'left', field: 'name' },
      { name: 'status', label: 'Status', align: 'left', field: 'status' },
      { name: 'actions', label: 'Actions', align: 'left' }
    ]

    async function fetchDeployments() {
      try {
        if (deployments.value.length === 0) loading.value = true
        const response = await fetch('/deployments')
        if (!response.ok) throw new Error('Failed to fetch deployments')
        const data = await response.json()
        deployments.value = data
        error.value = null
      } catch (err) {
        error.value = err.message
      } finally {
        loading.value = false
      }
    }

    onMounted(() => {
      fetchDeployments()
      intervalId = setInterval(fetchDeployments, 5000)
    })

    onBeforeUnmount(() => {
      if (intervalId) clearInterval(intervalId)
    })

    async function restartDeployment(namespace, name) {
      try {
        const response = await fetch('/restart', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ namespace, name })
        })
        if (!response.ok) throw new Error('Failed to restart deployment')
        $q.notify({
          type: 'positive',
          message: 'Restarting'
        })
      } catch (err) {
        $q.notify({
          type: 'negative',
          message: 'Error: ' + err.message
        })
      }
    }

    async function pauseDeployment(namespace, name) {
      try {
        const response = await fetch('/scale', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ namespace, name, replicas: 0 })
        })
        if (!response.ok) throw new Error('Failed to pause deployment')
        $q.notify({
          type: 'positive',
          message: 'Deployment paused'
        })
      } catch (err) {
        $q.notify({
          type: 'negative',
          message: 'Error: ' + err.message
        })
      }
    }

    async function resumeDeployment(namespace, name) {
      try {
        const response = await fetch('/scale', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ namespace, name, replicas: 1 })
        })
        if (!response.ok) throw new Error('Failed to resume deployment')
        $q.notify({
          type: 'positive',
          message: 'Deployment resumed'
        })
      } catch (err) {
        $q.notify({
          type: 'negative',
          message: 'Error: ' + err.message
        })
      }
    }

    async function showLogs(namespace, name) {
      try {
        const response = await fetch(`/logs/${namespace}/${name}`)
        if (!response.ok) throw new Error('Failed to fetch logs')
        const data = await response.json()
        deploymentLogs.value = data.logs || ''
        selectedPod.value = data.pod || ''
        logsModal.value = true
      } catch (err) {
        $q.notify({
          type: 'negative',
          message: 'Error: ' + err.message
        })
      }
    }    

    function deleteNamespace(namespace) {
      $q.dialog({
        title: 'Confirm',
        message: `Are you sure you want to delete the namespace "${namespace}"? This action cannot be undone.`,
        cancel: true,
        persistent: true
      }).onOk(async () => {
        try {
          const response = await fetch(`/namespace/${namespace}`, {
            method: 'DELETE'
          })
          if (!response.ok) throw new Error('Failed to delete namespace')
          $q.notify({
            type: 'positive',
            message: `Namespace ${namespace} deleted`
          })
          fetchDeployments()
        } catch (err) {
          $q.notify({
            type: 'negative',
            message: 'Error: ' + err.message
          })
        }
      })
    }

    return {
      deployments,
      loading,
      error,
      columns,
      logsModal,
      deploymentLogs,
      selectedPod,
      restartDeployment,
      pauseDeployment,
      resumeDeployment,
      showLogs,
      deleteNamespace
    }
  }
}
</script>