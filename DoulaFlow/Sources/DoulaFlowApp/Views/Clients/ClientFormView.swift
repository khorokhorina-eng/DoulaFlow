import SwiftUI

struct ClientFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Client
    var onSave: (Client) -> Void
    @State private var computedWeek: Int = 1

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
                    LabeledContent("Week") {
                        Text("Week \(computedWeek)")
                            .font(.body.monospacedDigit())
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medical notes (optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: Binding(
                            get: { draft.medicalNotes ?? "" },
                            set: { draft.medicalNotes = $0 }
                        ))
                        .frame(minHeight: 80)
                    }
                }
            }
            .navigationTitle("Client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var normalized = draft
                        normalized.pregnancyWeek = computedWeek
                        onSave(normalized)
                        dismiss()
                    }
                }
            }
            .onAppear {
                computedWeek = PregnancyWeekCalculator.week(edd: draft.estimatedDueDate)
            }
            .onChange(of: draft.estimatedDueDate) { newValue in
                computedWeek = PregnancyWeekCalculator.week(edd: newValue)
            }
        }
    }
}
