<template>
  <div>
    <h2>Upload File</h2>
    <q-form @submit.prevent="submitFile">
      <q-file
        v-model="selectedFile"
        label="Upload Your Application"
        filled
        :disable="loading"
        class="q-mb-md"
        @rejected="onRejected"
        counter
      >
        <template v-slot:prepend>
          <q-icon name="attach_file" />
        </template>
        <template v-slot:hint>
          File *.tgz
        </template>      
      </q-file>
      <q-btn
        label="Upload"
        type="submit"
        color="primary"
        :loading="loading"
        :disable="!selectedFile"
      />
    </q-form>
    <div v-if="message" class="q-mt-md">
      <q-banner :class="messageType === 'positive' ? 'bg-positive text-white' : 'bg-negative text-white'">
        {{ message }}
      </q-banner>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'

export default {
  name: 'UploadLink',
  setup() {
    const selectedFile = ref(null)
    const loading = ref(false)
    const message = ref('')
    const messageType = ref('positive')

    function onRejected() {
      message.value = 'File rejected. Please select a valid file.'
      messageType.value = 'negative'
      selectedFile.value = null
    }

    async function submitFile() {
      if (!selectedFile.value) return
      loading.value = true
      message.value = ''
      try {
        const formData = new FormData()
        formData.append('file', selectedFile.value)
        const response = await fetch('/upload', {
          method: 'POST',
          body: formData
        })
        if (!response.ok) throw new Error('Upload failed')
        const data = await response.json()
        message.value = data.message || 'File uploaded successfully'
        messageType.value = 'positive'
      } catch (err) {
        message.value = err.message
        messageType.value = 'negative'
      } finally {
        loading.value = false
      }
    }

    return {
      selectedFile,
      loading,
      message,
      messageType,
      onRejected,
      submitFile
    }
  }
}
</script>