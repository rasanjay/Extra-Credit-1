import from "@jac/mobui" { View, Text, Pressable, TextInput, ScrollView, StyleSheet }

import from ..main { Assignment, list_assignments, set_completed }

glob styles = StyleSheet.create({
    screen: {flex: 1, backgroundColor: "#f5f6f8"},
    content: {padding: 20, paddingTop: 64, paddingBottom: 40, gap: 16},
    title: {fontSize: 26, fontWeight: "bold", color: "#202b3c"},
    label: {fontSize: 16, fontWeight: "bold", color: "#202b3c"},
    text: {fontSize: 15, color: "#202b3c"},
    muted: {fontSize: 14, color: "#596579"},
    card: {backgroundColor: "white", borderRadius: 10, padding: 18, gap: 10},
    input: {borderWidth: 1, borderColor: "#bec7d4", borderRadius: 6, padding: 12, fontSize: 16, color: "#202b3c"},
    button: {backgroundColor: "#2458ad", borderRadius: 6, padding: 14, alignItems: "center"},
    buttonText: {color: "white", fontSize: 16, fontWeight: "bold"},
    error: {color: "#962d2d", fontSize: 15},
    done: {fontSize: 18, color: "#697586", textDecorationLine: "line-through"},
    assignmentTitle: {fontSize: 18, fontWeight: "bold", color: "#202b3c"}
});

def:pub app -> JsxElement {
    has server: str = "http://127.0.0.1:8000";
    has connected_server: str = "";
    has items: list[Assignment] = [];
    has busy: bool = False;
    has error: str = "";

    async def refresh {
        busy = True;
        error = "";
        items = [];
        connected_server = "";
        try {
            # Configure Jac's bridge for the planner running on your Mac.
            globalThis.__JAC_API_BASE_URL__ = server.strip().rstrip("/");
            items = await list_assignments();
            connected_server = server;
        } except Exception as e {
            error = f"Could not load assignments. Check the server address and Wi-Fi connection. {e}";
        } finally {
            busy = False;
        }
    }

    async def toggle(item: Assignment) {
        busy = True;
        error = "";
        try {
            await set_completed(item.id, not item.completed);
            items = await list_assignments();
        } except Exception as e {
            error = f"Could not update assignment: {e}";
        } finally {
            busy = False;
        }
    }

    return <ScrollView style={styles.screen} contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled">
        <Text style={styles.title}>Assignment Planner</Text>
        <Text style={styles.muted}>Check your coursework on the go.</Text>

        <View style={styles.card}>
            <Text style={styles.label}>Planner server</Text>
            <Text style={styles.muted}>On your iPhone, enter your Mac's Wi-Fi address with port 8000.</Text>
            <TextInput style={styles.input} value={server} editable={not busy}
                accessibilityLabel="Planner server address"
                autoCapitalize="none" autoCorrect={False} keyboardType="url"
                onChangeText={lambda (value: str) { server = value; }} />
            <Pressable style={styles.button} accessibilityRole="button" disabled={busy}
                onPress={refresh}>
                <Text style={styles.buttonText}>{"Loading..." if busy else "Load / refresh assignments"}</Text>
            </Pressable>
        </View>

        {<Text style={styles.error} accessibilityRole="alert">{error}</Text> if error else None}
        {<Text style={styles.muted}>No assignments yet. Add one on the web or through the CLI.</Text>
            if connected_server and len(items) == 0 and not busy else None}
        {<Text style={styles.label}>Your assignments · earliest due first</Text> if len(items) > 0 else None}

        {[
            <View style={styles.card} key={item.id}>
                <Text style={styles.muted}>{item.course} · {"Completed" if item.completed else "Open"}</Text>
                <Text style={styles.done if item.completed else styles.assignmentTitle}>{item.title}</Text>
                <Text style={styles.text}>Due {item.due_date}</Text>
                {<Text style={styles.muted}>{item.estimated_minutes} minutes estimated</Text>
                    if item.estimated_minutes is not None else None}
                {<Text style={styles.text}>{item.description}</Text> if item.description else None}
                <Pressable style={styles.button} accessibilityRole="button" disabled={busy}
                    onPress={lambda { toggle(item); }}>
                    <Text style={styles.buttonText}>{"Reopen" if item.completed else "Mark complete"}</Text>
                </Pressable>
            </View> for item in items
        ]}
    </ScrollView>;
}
