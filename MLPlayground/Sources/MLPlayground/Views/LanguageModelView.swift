import SwiftUI

struct LanguageModelView: View {
    @EnvironmentObject var modelManager: MLModelManager
    @StateObject private var languageProcessor = LanguageProcessor()

    @State private var inputText = ""
    @State private var outputText = ""
    @State private var selectedTask: LanguageTask = .sentiment
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    taskSelector
                    inputSection
                    processButton
                    if isProcessing {
                        processingView
                    }
                    if !outputText.isEmpty {
                        outputSection
                    }
                    if let error = errorMessage {
                        errorView(error)
                    }
                    modelInfoSection
                }
                .padding()
            }
            .navigationTitle("Language Model")
        }
    }

    // MARK: - Task Selector

    private var taskSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Task")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LanguageTask.allCases) { task in
                        TaskChip(
                            task: task,
                            isSelected: selectedTask == task
                        ) {
                            selectedTask = task
                            outputText = ""
                        }
                    }
                }
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Input Text")
                    .font(.headline)
                Spacer()
                Text("\(inputText.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $inputText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            if inputText.isEmpty {
                Text(selectedTask.placeholder)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Process Button

    private var processButton: some View {
        Button {
            processText()
        } label: {
            HStack {
                Image(systemName: selectedTask.icon)
                Text("Process with \(selectedTask.rawValue)")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Processing text...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Output Section

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Result")
                    .font(.headline)
                Spacer()
                Button {
                    UIPasteboard.general.string = outputText
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
            }

            Text(outputText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Model Info Section

    private var modelInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Language Processing")
                .font(.headline)

            Text("This app uses on-device ML models to process text. You can perform various NLP tasks like sentiment analysis, text summarization, and more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                InfoRow(label: "Framework", value: "Natural Language + Core ML")
                InfoRow(label: "Model", value: languageProcessor.currentModelName)
                InfoRow(label: "Processing", value: "On-device")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helper Methods

    private func processText() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isProcessing = true
        errorMessage = nil
        outputText = ""

        Task {
            do {
                let result = try await languageProcessor.process(
                    text: inputText,
                    task: selectedTask
                )
                await MainActor.run {
                    outputText = result
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Processing failed: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Task Chip

struct TaskChip: View {
    let task: LanguageTask
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: task.icon)
                    .font(.caption)
                Text(task.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LanguageModelView()
        .environmentObject(MLModelManager())
}
