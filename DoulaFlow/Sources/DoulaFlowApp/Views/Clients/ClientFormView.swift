import SwiftUI

struct ClientFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Client
    var onSave: (Client) -> Void

    init(client: Client, onSave: @escaping (Client) -> Void) {
        _draft = State(initialValue: client)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Client Name", text: $draft.name)
                    TextField("Contact", text: $draft.contactDetails)
                }

                Section("Pregnancy") {
                    DatePicker("EDD", selection: $draft.estimatedDueDate, displayedComponents: [.date])
                    Stepper(value: $draft.pregnancyWeek, in: 4...42) {
                        Text("Week \(draft.pregnancyWeek)")
                    }
                    Picker("Status", selection: $draft.status) {
                        ForEach(Client.Status.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $draft.notes)
                        .frame(minHeight: 80)
                    TextEditor(text: Binding(
                        get: { draft.medicalNotes ?? "" },
                        set: { draft.medicalNotes = $0 }
                    ))
                    .frame(minHeight: 80)
                }
            }
            .navigationTitle("Client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                }
            }
        }
    }
}
