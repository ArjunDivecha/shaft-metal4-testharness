import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = HarnessViewModel()
    @State private var showingDocumentPicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Metal capability banner
                    capabilityBanner

                    // Model selection
                    modelSection

                    // Backend selection
                    backendSection

                    // Run type selection
                    runTypeSection

                    // Run button
                    runButton

                    // Live metrics (during run)
                    if case .running = viewModel.modelState {
                        liveMetricsView
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        errorView(error)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Metal Tensor Harness")
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { url in
                    viewModel.importModel(from: url)
                }
            }
            .sheet(isPresented: $viewModel.showingResults) {
                if let result = viewModel.currentResult {
                    ResultsView(result: result, viewModel: viewModel)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Capability Banner

    private var capabilityBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: viewModel.metal4Available ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.metal4Available ? .green : .orange)
                Text(viewModel.metal4Available ? "Metal-4 Tensor API Available" : "Metal-4 Tensor API Unavailable")
                    .font(.headline)
            }

            Text(viewModel.metalCapabilityInfo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(viewModel.metal4Available ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Model Section

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model")
                .font(.headline)

            if let model = viewModel.selectedModel {
                modelInfoCard(model)
            } else {
                Button(action: { showingDocumentPicker = true }) {
                    Label("Import Model", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }

    private func modelInfoCard(_ model: ModelInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.filename)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Label(String(format: "%.2f GB", model.sizeGB), systemImage: "doc")
                Spacer()
                if let quant = model.quantization {
                    Label(quant, systemImage: "cube")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if let ram = model.estimatedRAMMB {
                Text("Est. RAM: \(ram) MB")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Button("Change Model") {
                showingDocumentPicker = true
            }
            .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Backend Section

    private var backendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Backend")
                .font(.headline)

            Picker("Backend", selection: $viewModel.selectedBackend) {
                ForEach(Backend.allCases) { backend in
                    HStack {
                        Text(backend.displayName)
                        if !viewModel.metalCapability.isBackendAvailable(backend) {
                            Text("(unavailable)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tag(backend)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!isIdle)
        }
    }

    // MARK: - Run Type Section

    private var runTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Run Type")
                .font(.headline)

            Picker("Run Type", selection: $viewModel.selectedRunType) {
                ForEach(RunType.allCases) { runType in
                    Text(runType.displayName).tag(runType)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!isIdle)
        }
    }

    // MARK: - Run Button

    private var runButton: some View {
        Button(action: {
            viewModel.runBenchmark()
        }) {
            HStack {
                if case .running = viewModel.modelState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(buttonTitle)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canRun ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canRun)
    }

    private var buttonTitle: String {
        switch viewModel.modelState {
        case .idle: return "Run Benchmark"
        case .loading: return "Loading Model..."
        case .warmup: return "Warming Up..."
        case .running(let progress):
            return String(format: "Running... %.0f%%", progress * 100)
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    private var canRun: Bool {
        viewModel.selectedModel != nil && isIdle
    }

    private var isIdle: Bool {
        if case .idle = viewModel.modelState { return true }
        if case .completed = viewModel.modelState { return true }
        if case .failed = viewModel.modelState { return true }
        return false
    }

    // MARK: - Live Metrics View

    private var liveMetricsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Metrics")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Tokens/sec")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", viewModel.liveMetrics.currentTokensPerSecond))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.liveMetrics.tokensGenerated)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }

            HStack {
                Text(viewModel.liveMetrics.currentThermalState.emoji)
                Text(viewModel.liveMetrics.currentThermalState.rawValue.capitalized)
                    .font(.caption)
                Spacer()
                Text("\(viewModel.liveMetrics.currentMemoryMB) MB")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
            Text(error)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.1))
        .foregroundColor(.red)
        .cornerRadius(8)
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType(filenameExtension: "gguf")!], asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
