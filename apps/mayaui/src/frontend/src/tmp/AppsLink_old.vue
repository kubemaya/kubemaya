<!--<template>
  <div>
    <h2>Apps</h2>
    <p>This is the AppsLink component. Replace this with your actual app content.</p>
  </div>
</template>

<script>
export default {
  name: 'AppsLink'
}
</script>-->

<template>
  <div>
    <h2>Apps</h2>
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">{{ error }}</div>
    <div v-else>
      <q-btn
        v-for="word in words"
        :key="word"
        :label="word"
        color="primary"
        class="q-mr-sm q-mb-sm"
        @click="openWord(word)"
      />
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'

export default {
  name: 'AppsLink',
  setup() {
    const words = ref([])
    const loading = ref(true)
    const error = ref(null)

    onMounted(async () => {
      try {
        // Replace with your actual API endpoint
        const response = await fetch('https://random-word-api.herokuapp.com/word')
        if (!response.ok) throw new Error('Failed to fetch words')
        const data = await response.json()
        console.log(data);
        //words.value = data.words || []
        words.value = data || []
      } catch (err) {
        error.value = err.message
      } finally {
        loading.value = false
      }
    })

    function openWord(word) {
      window.open(`/${word}`, '_blank')
    }

    return {
      words,
      loading,
      error,
      openWord
    }
  }
}
</script>