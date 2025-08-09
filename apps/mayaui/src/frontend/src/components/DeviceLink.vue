<template>
  <div>
    <h2>Device Status</h2>
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">{{ error }}</div>
    <div v-else class="row q-gutter-md">
      <div class="column items-center">
        <q-circular-progress
          :value="memoryPercent"
          size="80px"
          color="primary"
          show-value
        >
          <div class="text-center">
            <div>Memory</div>
            <div>{{ memoryPercent.toFixed(1) }}%</div>
          </div>
        </q-circular-progress>
      </div>
      <div class="column items-center">
        <q-circular-progress
          :value="cpuPercent"
          size="80px"
          color="secondary"
          show-value
        >
          <div class="text-center">
            <div>CPU</div>
            <div>{{ cpuPercent.toFixed(1) }}%</div>
          </div>
        </q-circular-progress>
      </div>
      <div class="column items-center">
        <q-circular-progress
          :value="diskPercent"
          size="80px"
          color="accent"
          show-value
        >
          <div class="text-center">
            <div>Disk</div>
            <div>{{ diskPercent.toFixed(1) }}%</div>
          </div>
        </q-circular-progress>
      </div>
      <div class="column items-center">
        <q-circular-progress
          :value="swapPercent"
          size="80px"
          color="deep-orange"
          show-value
        >
          <div class="text-center">
            <div>Swap</div>
            <div>{{ swapPercent.toFixed(1) }}%</div>
          </div>
        </q-circular-progress>
      </div>
      <div class="row q-gutter-md q-mt-md">
        <q-btn color="primary" label="Restart" @click="runRestart()" />
        <q-btn color="secondary" label="Shutdown" @click="runShutdown()" />
      </div>      
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'

export default {
  name: 'DeviceLink',
  setup() {
    const loading = ref(true)
    const error = ref(null)
    const device = ref({})
    let intervalId = null

    const memoryPercent = computed(() => {
      if (!device.value.memory_total) return 0
      return 100 - (device.value.memory_available / device.value.memory_total) * 100
    })
    const cpuPercent = computed(() => (device.value.cpu_percent * 100) || 0)
    const diskPercent = computed(() => {
      if (!device.value.disk_total) return 0
      return 100 - (device.value.disk_free / device.value.disk_total) * 100
    })
    const swapPercent = computed(() => {
      if (!device.value.swap_total) return 0
      return device.value.swap_total === 0 ? 0 : 100 - (device.value.swap_free / device.value.swap_total) * 100
    })

    async function fetchDevice() {
      try {
        if (!device.value.memory_total) loading.value = true
        const response = await fetch('/device')
        if (!response.ok) throw new Error('Failed to fetch device info')
        const data = await response.json()
        device.value = data
        error.value = null
      } catch (err) {
        error.value = err.message
      } finally {
        loading.value = false
      }
    }

    async function runRestart() {
      runShell('echo "reboot" > /app/shell/script.sh')
    }
    async function runShutdown() {
      runShell('echo "shutdown -h now" > /app/shell/script.sh')
    }
    async function runShell(cmd) {
      //shellOutput.value = ''
      try {
        /*const response = await fetch('/shell', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ cmd })
        })*/
        await fetch('/shell', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ "cmd":cmd })
        })        
        /*const data = await response.json()
        shellOutput.value = data.output || data.error || JSON.stringify(data)*/
      } catch (err) {
        //shellOutput.value = 'Error: ' + err.message
        console.log(err.message)
      }
    }

    onMounted(() => {
      fetchDevice()
      intervalId = setInterval(fetchDevice, 5000)
    })

    onBeforeUnmount(() => {
      if (intervalId) clearInterval(intervalId)
    })

    return {
      loading,
      error,
      memoryPercent,
      cpuPercent,
      diskPercent,
      swapPercent,
      runShell,
      runRestart,
      runShutdown
    }
  }
}
</script>