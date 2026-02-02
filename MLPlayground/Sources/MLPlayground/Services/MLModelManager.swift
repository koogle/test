import SwiftUI
import CoreML

@MainActor
class MLModelManager: ObservableObject {
    @Published var availableImageModels: [MLModelInfo] = []
    @Published var availableLanguageModels: [MLModelInfo] = []
    @Published var isLoading = false

    init() {
        loadAvailableModels()
    }

    func loadAvailableModels() {
        // Default built-in models
        availableImageModels = [
            MLModelInfo(
                name: "MobileNetV2",
                description: "Fast image classification model",
                type: .image,
                isBuiltIn: true
            ),
            MLModelInfo(
                name: "ResNet50",
                description: "Accurate image classification model",
                type: .image,
                isBuiltIn: true
            )
        ]

        availableLanguageModels = [
            MLModelInfo(
                name: "NaturalLanguage",
                description: "Built-in NLP framework",
                type: .language,
                isBuiltIn: true
            ),
            MLModelInfo(
                name: "BERT",
                description: "Text understanding model",
                type: .language,
                isBuiltIn: false
            )
        ]

        // Scan for custom .mlmodel files in the documents directory
        scanForCustomModels()
    }

    private func scanForCustomModels() {
        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else { return }

        let modelsURL = documentsURL.appendingPathComponent("MLModels")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: modelsURL,
            withIntermediateDirectories: true
        )

        // Scan for .mlmodel and .mlmodelc files
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: modelsURL,
            includingPropertiesForKeys: nil
        ) else { return }

        for file in files {
            if file.pathExtension == "mlmodelc" || file.pathExtension == "mlmodel" {
                let modelInfo = MLModelInfo(
                    name: file.deletingPathExtension().lastPathComponent,
                    description: "Custom model",
                    type: .custom,
                    isBuiltIn: false,
                    url: file
                )

                // Determine type based on model metadata if possible
                availableImageModels.append(modelInfo)
            }
        }
    }

    func importModel(from url: URL) async throws {
        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw MLModelError.importFailed("Could not access documents directory")
        }

        let modelsURL = documentsURL.appendingPathComponent("MLModels")
        let destinationURL = modelsURL.appendingPathComponent(url.lastPathComponent)

        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw MLModelError.importFailed("Could not access file")
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        try FileManager.default.copyItem(at: url, to: destinationURL)

        // Reload models
        await MainActor.run {
            loadAvailableModels()
        }
    }
}

// MARK: - Supporting Types

struct MLModelInfo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let type: ModelType
    let isBuiltIn: Bool
    var url: URL?

    enum ModelType {
        case image
        case language
        case custom
    }
}

enum MLModelError: LocalizedError {
    case importFailed(String)
    case modelNotFound
    case predictionFailed(String)

    var errorDescription: String? {
        switch self {
        case .importFailed(let reason):
            return "Failed to import model: \(reason)"
        case .modelNotFound:
            return "Model not found"
        case .predictionFailed(let reason):
            return "Prediction failed: \(reason)"
        }
    }
}
