import SwiftUI

// MARK: - Model Picker View
// This view is currently not used (we use DocumentPicker directly)
// but is kept for future enhancements like model management

struct ModelPickerView: View {
    @Binding var selectedModel: ModelInfo?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Model Selection")
                    .font(.title)
                    .padding()

                if let model = selectedModel {
                    modelCard(model)
                        .padding()
                } else {
                    Text("No model selected")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer()

                Button("Select from Files") {
                    // This would trigger the document picker
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Select Model")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func modelCard(_ model: ModelInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.filename)
                .font(.headline)

            HStack {
                Label(String(format: "%.2f GB", model.sizeGB), systemImage: "doc.fill")
                Spacer()
                if let quant = model.quantization {
                    Label(quant, systemImage: "cube.fill")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if let ctx = model.contextLength {
                Label("\(ctx) context", systemImage: "text.alignleft")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let ram = model.estimatedRAMMB {
                HStack {
                    Image(systemName: "memorychip")
                    Text("Est. RAM: \(ram) MB")
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct ModelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelPickerView(selectedModel: .constant(nil))
    }
}
