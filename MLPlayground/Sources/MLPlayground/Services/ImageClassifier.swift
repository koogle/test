import SwiftUI
import CoreML
import Vision

@MainActor
class ImageClassifier: ObservableObject {
    @Published var currentModelName = "MobileNetV2"
    @Published var isModelLoaded = false

    private var vnModel: VNCoreMLModel?

    init() {
        loadDefaultModel()
    }

    private func loadDefaultModel() {
        // The default model will be loaded when classify is called
        // For now, we use Vision's built-in classification
        isModelLoaded = true
    }

    func classify(image: UIImage) async throws -> [ClassificationResult] {
        guard let cgImage = image.cgImage else {
            throw ImageClassifierError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: ImageClassifierError.classificationFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: ImageClassifierError.noResults)
                    return
                }

                // Get top 5 results
                let results = observations.prefix(5).map { observation in
                    ClassificationResult(
                        label: observation.identifier.capitalized,
                        confidence: Double(observation.confidence)
                    )
                }

                continuation.resume(returning: Array(results))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ImageClassifierError.classificationFailed(error.localizedDescription))
            }
        }
    }

    func classifyWithCustomModel(image: UIImage, modelURL: URL) async throws -> [ClassificationResult] {
        guard let cgImage = image.cgImage else {
            throw ImageClassifierError.invalidImage
        }

        // Compile the model if needed
        let compiledURL: URL
        if modelURL.pathExtension == "mlmodel" {
            compiledURL = try await compileModel(at: modelURL)
        } else {
            compiledURL = modelURL
        }

        let model = try MLModel(contentsOf: compiledURL)
        let vnModel = try VNCoreMLModel(for: model)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: ImageClassifierError.classificationFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: ImageClassifierError.noResults)
                    return
                }

                let results = observations.prefix(5).map { observation in
                    ClassificationResult(
                        label: observation.identifier.capitalized,
                        confidence: Double(observation.confidence)
                    )
                }

                continuation.resume(returning: Array(results))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ImageClassifierError.classificationFailed(error.localizedDescription))
            }
        }
    }

    private func compileModel(at url: URL) async throws -> URL {
        return try await Task.detached {
            try MLModel.compileModel(at: url)
        }.value
    }
}

// MARK: - Classification Result

struct ClassificationResult: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Double
}

// MARK: - Errors

enum ImageClassifierError: LocalizedError {
    case invalidImage
    case classificationFailed(String)
    case noResults
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid"
        case .classificationFailed(let reason):
            return "Classification failed: \(reason)"
        case .noResults:
            return "No classification results"
        case .modelNotLoaded:
            return "Model is not loaded"
        }
    }
}
