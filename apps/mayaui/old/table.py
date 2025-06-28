from nicegui import events, ui

def demoTable(): 
    columns = [
        {'name': 'name', 'label': 'Name', 'field': 'name', 'align': 'left'},
        {'name': 'age', 'label': 'Age', 'field': 'age'},
    ]
    rows = [
        {'id': 0, 'name': 'Alice', 'age': 18},
        {'id': 1, 'name': 'Bob', 'age': 21},
        {'id': 2, 'name': 'Carol', 'age': 20},
    ]

    def restart(e: events.GenericEventArguments) -> None:
        ui.notify(f'Restart row with ID {e.args["id"]} {e.args["name"]} {e.args["age"]}')
        table.update()


    table = ui.table(columns=columns, rows=rows, row_key='name').classes('w-60')
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
            <q-td key="name" :props="props">
                {{ props.row.name }}
                <q-popup-edit v-model="props.row.name" v-slot="scope"
                    @update:model-value="() => $parent.$emit('rename', props.row)"
                >
                    <q-input v-model="scope.value" dense autofocus counter @keyup.enter="scope.set" />
                </q-popup-edit>
            </q-td>
            <q-td key="age" :props="props">
                {{ props.row.age }}
                <q-popup-edit v-model="props.row.age" v-slot="scope"
                    @update:model-value="() => $parent.$emit('rename', props.row)"
                >
                    <q-input v-model.number="scope.value" type="number" dense autofocus counter @keyup.enter="scope.set" />
                </q-popup-edit>
            </q-td>
        </q-tr>
    ''')
    table.on('restart', restart)
