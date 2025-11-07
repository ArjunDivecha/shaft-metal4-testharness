import SwiftUI

struct ResultsView: View {
    let result: BenchmarkResult
    @ObservedObject var viewModel: HarnessViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var exportURLs: [URL] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection

                    // Performance metrics
                    metricsSection

                    // Thermal section
                    thermalSection

                    // Comparison section (if available)
                    if result.comparisonResult != nil {
                        comparisonSection
                    } else {
                        comparisonPromptSection
                    }

                    // Actions
                    actionButtons

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.backend.displayName)
                .font(.title)
                .fontWeight(.bold)

            Text(result.modelInfo.filename)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(result.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)

            metricCard(
                title: "Time to First Token",
                value: String(format: "%.0f ms", result.ttftMs),
                icon: "timer"
            )

            metricCard(
                title: "Tokens per Second",
                value: String(format: "%.1f t/s", result.tokensPerSecond),
                icon: "speedometer"
            )

            metricCard(
                title: "Total Tokens",
                value: "\(result.totalTokens)",
                icon: "number"
            )

            metricCard(
                title: "Duration",
                value: String(format: "%.1f s", result.durationMs / 1000),
                icon: "clock"
            )

            metricCard(
                title: "Peak Memory",
                value: "\(result.peakMemoryMB) MB",
                icon: "memorychip"
            )
        }
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 32)
                .foregroundColor(.blue)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Thermal Section

    private var thermalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thermal Profile")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("States Observed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        ForEach(Array(Set(result.thermalStates)), id: \.self) { state in
                            Text(state.emoji)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Throttling Events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.throttlingEvents)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(result.throttlingEvents > 0 ? .orange : .green)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Correctness Comparison")
                .font(.headline)

            if let comparison = result.comparisonResult {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("vs. \(comparison.baselineBackend.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%% match", comparison.matchPercentage))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(comparisonColor(comparison.matchPercentage))
                    }

                    HStack {
                        Text("Edit Distance:")
                            .font(.caption)
                        Text("\(comparison.editDistance)")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    if let notes = comparison.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private func comparisonColor(_ percentage: Double) -> Color {
        if percentage >= 99.0 { return .green }
        if percentage >= 95.0 { return .orange }
        return .red
    }

    private var comparisonPromptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Run Comparison")
                .font(.headline)

            Button(action: {
                let baselineBackend: Backend = result.backend == .metalTensor ? .metalLegacy : .metalTensor
                viewModel.runComparison(baselineBackend: baselineBackend)
                dismiss()
            }) {
                Label("Compare with \(suggestedComparisonBackend.displayName)", systemImage: "arrow.left.arrow.right")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Text("Runs the same test with a different backend to verify correctness")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var suggestedComparisonBackend: Backend {
        result.backend == .metalTensor ? .metalLegacy : .metalTensor
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                exportURLs = viewModel.exportResults()
                showingShareSheet = true
            }) {
                Label("Export Results", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Button(action: {
                viewModel.reset()
                dismiss()
            }) {
                Label("New Test", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let rootVC = window.rootViewController {
                ShareSheet(urls: exportURLs)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let urls: [URL]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleResult = BenchmarkResult(
            backend: .metalTensor,
            modelInfo: ModelInfo(
                filename: "phi-3.5-mini-Q4_K_M.gguf",
                path: "/path/to/model",
                sizeBytes: 2_400_000_000,
                quantization: "Q4_K_M",
                contextLength: 4096
            ),
            runType: .sanity,
            ttftMs: 245.0,
            tokensPerSecond: 28.3,
            totalTokens: 128,
            durationMs: 4500.0,
            peakMemoryMB: 3421,
            thermalStates: [.nominal, .fair, .fair],
            throttlingEvents: 0
        )

        ResultsView(result: sampleResult, viewModel: HarnessViewModel())
    }
}
