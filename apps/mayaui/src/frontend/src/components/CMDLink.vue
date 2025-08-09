<template>
  <div>
    <h2>Shell Command Runner</h2>
    <codemirror
      v-model="command"
      :options="cmOptions"
      style="height: 120px; border: 1px solid #ccc;"
    />
    <q-btn
      label="Run"
      color="primary"
      class="q-mt-md"
      @click="runCommand"
      :loading="loading"
    />
    <q-input
      v-model="output"
      type="textarea"
      label="Output"
      :dense="dense"
      filled
      readonly
      autogrow
      class="q-mt-md"
      style="font-family: 'Courier New', Courier, monospace;"
    />
  </div>
</template>

<script>
import { ref } from 'vue'
import { Codemirror } from 'vue-codemirror'
/*import 'codemirror/lib/codemirror.css'
import 'codemirror/mode/shell/shell.js'*/

export default {
  name: 'CmdLink',
  components: { codemirror: Codemirror },
  setup() {
    const command = ref('')
    const output = ref('')
    const loading = ref(false)
    const cmOptions = {
      mode: 'shell',
      theme: 'default',
      lineNumbers: true,
      tabSize: 2,
      autofocus: true,
    }

    async function runCommand() {
      if (!command.value.trim()) {
        output.value = 'Please enter a command.'
        return
      }
      loading.value = true
      output.value = ''
      try {
        const response = await fetch('/shell', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ "cmd": command.value })
        })
        const data = await response.json()
        output.value = data.output || data.error || JSON.stringify(data)
      } catch (err) {
        output.value = 'Error: ' + err.message
      } finally {
        loading.value = false
      }
    }

    return {
      command,
      output,
      loading,
      cmOptions,
      runCommand
    }
  }
}
</script>