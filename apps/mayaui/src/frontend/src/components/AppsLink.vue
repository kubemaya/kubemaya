<template>
  <div>
    <h3>Apps</h3>
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">{{ error }}</div>
    <div v-else>
      <div v-if="notFound">
        Applications not found
      </div>
      <div v-else>
        <q-btn
          v-for="app in apps"
          :key="app"
          :label="app"
          color="primary"
          class="q-mr-sm q-mb-sm"
          @click="openApp(app)"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onBeforeUnmount } from 'vue'

export default {
  name: 'AppsLink',
  setup() {
    const apps = ref([])
    const loading = ref(true)
    const error = ref(null)
    const notFound = ref(false)
    let intervalId = null

    async function fetchApps() {
      try {
        if (apps.value.length === 0) loading.value = true
        const response = await fetch('/namespaces')
        if (!response.ok) throw new Error('Failed to fetch apps')
        const data = await response.json()
        apps.value = data || []
        notFound.value = (apps.value.length === 0)
        error.value = null
      } catch (err) {
        error.value = err.message
        notFound.value = false
      } finally {
        loading.value = false
      }
    }

    onMounted(() => {
      fetchApps()
      intervalId = setInterval(fetchApps, 5000)
    })

    onBeforeUnmount(() => {
      if (intervalId) clearInterval(intervalId)
    })

    function openApp(name) {
      console.log("-" + name + "-")
      window.open(`/${name}`, '_blank')
    }

    return {
      apps,
      loading,
      error,
      openApp,
      notFound
    }
  }
}
</script>