import SwiftUI
import PhotosUI

struct ImageModelView: View {
    @EnvironmentObject var modelManager: MLModelManager
    @StateObject private var imageClassifier = ImageClassifier()

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var classificationResults: [ClassificationResult] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imageSection
                    imageSourceButtons
                    if isProcessing {
                        processingView
                    }
                    if !classificationResults.isEmpty {
                        resultsSection
                    }
                    if let error = errorMessage {
                        errorView(error)
                    }
                    modelInfoSection
                }
                .padding()
            }
            .navigationTitle("Image Classification")
            .sheet(isPresented: $showCamera) {
                CameraView(image: $selectedImage)
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    await loadImage(from: newValue)
                }
            }
            .onChange(of: selectedImage) { _, newValue in
                if let image = newValue {
                    classifyImage(image)
                }
            }
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
            } else {
                placeholderView
            }
        }
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 250)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("Select an image to classify")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
    }

    // MARK: - Source Buttons

    private var imageSourceButtons: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Gallery", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                showCamera = true
            } label: {
                Label("Camera", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing image...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Classification Results")
                .font(.headline)

            ForEach(classificationResults) { result in
                ClassificationResultRow(result: result)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Model Info Section

    private var modelInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Image Classification")
                .font(.headline)

            Text("This app uses Core ML to run image classification models on-device. You can use built-in models like MobileNetV2 or add your own .mlmodel files.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                InfoRow(label: "Framework", value: "Vision + Core ML")
                InfoRow(label: "Model", value: imageClassifier.currentModelName)
                InfoRow(label: "Processing", value: "On-device")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helper Methods

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
            }
        }
    }

    private func classifyImage(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil
        classificationResults = []

        Task {
            do {
                let results = try await imageClassifier.classify(image: image)
                await MainActor.run {
                    classificationResults = results
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Classification failed: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ClassificationResultRow: View {
    let result: ClassificationResult

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(result.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            Text(String(format: "%.1f%%", result.confidence * 100))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(confidenceColor)
        }
        .padding(.vertical, 4)
    }

    private var confidenceColor: Color {
        switch result.confidence {
        case 0.7...: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ImageModelView()
        .environmentObject(MLModelManager())
}
