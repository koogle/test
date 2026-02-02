import SwiftUI
import NaturalLanguage

@MainActor
class LanguageProcessor: ObservableObject {
    @Published var currentModelName = "NaturalLanguage"
    @Published var isModelLoaded = true

    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .lemma, .sentimentScore])

    func process(text: String, task: LanguageTask) async throws -> String {
        switch task {
        case .sentiment:
            return try await analyzeSentiment(text)
        case .entities:
            return try await extractEntities(text)
        case .language:
            return try await detectLanguage(text)
        case .tokenize:
            return try await tokenize(text)
        case .lemmatize:
            return try await lemmatize(text)
        case .summarize:
            return try await summarize(text)
        }
    }

    // MARK: - Sentiment Analysis

    private func analyzeSentiment(_ text: String) async throws -> String {
        return await Task.detached {
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            tagger.string = text

            var results: [(String, Double)] = []

            // Analyze sentiment per sentence
            let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            for sentence in sentences {
                tagger.string = sentence
                let range = sentence.startIndex..<sentence.endIndex
                let (sentiment, _) = tagger.tag(at: range.lowerBound, unit: .paragraph, scheme: .sentimentScore)

                if let sentimentValue = sentiment?.rawValue, let score = Double(sentimentValue) {
                    results.append((sentence, score))
                }
            }

            // Calculate overall sentiment
            let overallScore: Double
            if results.isEmpty {
                tagger.string = text
                let range = text.startIndex..<text.endIndex
                let (sentiment, _) = tagger.tag(at: range.lowerBound, unit: .paragraph, scheme: .sentimentScore)
                overallScore = Double(sentiment?.rawValue ?? "0") ?? 0
            } else {
                overallScore = results.map { $0.1 }.reduce(0, +) / Double(max(results.count, 1))
            }

            let sentimentLabel: String
            let emoji: String
            switch overallScore {
            case 0.1...:
                sentimentLabel = "Positive"
                emoji = "😊"
            case -0.1..<0.1:
                sentimentLabel = "Neutral"
                emoji = "😐"
            default:
                sentimentLabel = "Negative"
                emoji = "😔"
            }

            var output = "Overall Sentiment: \(sentimentLabel) \(emoji)\n"
            output += "Score: \(String(format: "%.2f", overallScore)) (range: -1 to 1)\n\n"

            if !results.isEmpty {
                output += "Per-sentence analysis:\n"
                for (sentence, score) in results.prefix(5) {
                    let shortSentence = sentence.prefix(50)
                    output += "• \"\(shortSentence)...\" → \(String(format: "%.2f", score))\n"
                }
            }

            return output
        }.value
    }

    // MARK: - Entity Extraction

    private func extractEntities(_ text: String) async throws -> String {
        return await Task.detached {
            let tagger = NLTagger(tagSchemes: [.nameType])
            tagger.string = text

            let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

            var entities: [String: [String]] = [
                "People": [],
                "Places": [],
                "Organizations": []
            ]

            tagger.enumerateTags(
                in: text.startIndex..<text.endIndex,
                unit: .word,
                scheme: .nameType,
                options: options
            ) { tag, tokenRange in
                if let tag = tag {
                    let entity = String(text[tokenRange])
                    switch tag {
                    case .personalName:
                        if !entities["People"]!.contains(entity) {
                            entities["People"]!.append(entity)
                        }
                    case .placeName:
                        if !entities["Places"]!.contains(entity) {
                            entities["Places"]!.append(entity)
                        }
                    case .organizationName:
                        if !entities["Organizations"]!.contains(entity) {
                            entities["Organizations"]!.append(entity)
                        }
                    default:
                        break
                    }
                }
                return true
            }

            var output = "Named Entities Found:\n\n"

            for (category, items) in entities where !items.isEmpty {
                output += "📌 \(category):\n"
                for item in items {
                    output += "   • \(item)\n"
                }
                output += "\n"
            }

            if entities.values.allSatisfy({ $0.isEmpty }) {
                output += "No named entities detected in the text."
            }

            return output
        }.value
    }

    // MARK: - Language Detection

    private func detectLanguage(_ text: String) async throws -> String {
        return await Task.detached {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)

            var output = "Language Detection Results:\n\n"

            if let dominantLanguage = recognizer.dominantLanguage {
                let languageName = Locale.current.localizedString(forLanguageCode: dominantLanguage.rawValue) ?? dominantLanguage.rawValue
                output += "Primary Language: \(languageName)\n\n"
            }

            let hypotheses = recognizer.languageHypotheses(withMaximum: 5)
            if !hypotheses.isEmpty {
                output += "Confidence Scores:\n"
                for (language, confidence) in hypotheses.sorted(by: { $0.value > $1.value }) {
                    let languageName = Locale.current.localizedString(forLanguageCode: language.rawValue) ?? language.rawValue
                    output += "• \(languageName): \(String(format: "%.1f%%", confidence * 100))\n"
                }
            }

            return output
        }.value
    }

    // MARK: - Tokenization

    private func tokenize(_ text: String) async throws -> String {
        return await Task.detached {
            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.string = text

            var tokens: [String] = []
            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
                tokens.append(String(text[tokenRange]))
                return true
            }

            var output = "Tokenization Results:\n\n"
            output += "Total tokens: \(tokens.count)\n\n"
            output += "Tokens:\n"
            output += tokens.joined(separator: " | ")

            // Word frequency
            let frequency = Dictionary(tokens.map { ($0.lowercased(), 1) }, uniquingKeysWith: +)
            let sortedFrequency = frequency.sorted { $0.value > $1.value }

            output += "\n\nWord Frequency (top 10):\n"
            for (word, count) in sortedFrequency.prefix(10) {
                output += "• \"\(word)\": \(count)\n"
            }

            return output
        }.value
    }

    // MARK: - Lemmatization

    private func lemmatize(_ text: String) async throws -> String {
        return await Task.detached {
            let tagger = NLTagger(tagSchemes: [.lemma])
            tagger.string = text

            var results: [(String, String)] = []

            tagger.enumerateTags(
                in: text.startIndex..<text.endIndex,
                unit: .word,
                scheme: .lemma,
                options: [.omitPunctuation, .omitWhitespace]
            ) { tag, tokenRange in
                let word = String(text[tokenRange])
                let lemma = tag?.rawValue ?? word
                if word.lowercased() != lemma.lowercased() {
                    results.append((word, lemma))
                }
                return true
            }

            var output = "Lemmatization Results:\n\n"

            if results.isEmpty {
                output += "All words are already in their base form."
            } else {
                output += "Word → Base Form:\n"
                for (word, lemma) in results {
                    output += "• \(word) → \(lemma)\n"
                }
            }

            return output
        }.value
    }

    // MARK: - Summarization (Extractive)

    private func summarize(_ text: String) async throws -> String {
        return await Task.detached {
            // Simple extractive summarization based on sentence importance
            let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard sentences.count > 1 else {
                return "Text is too short to summarize. Please provide more content."
            }

            // Score sentences based on word frequency
            let tokenizer = NLTokenizer(unit: .word)
            var wordFrequency: [String: Int] = [:]

            for sentence in sentences {
                tokenizer.string = sentence
                tokenizer.enumerateTokens(in: sentence.startIndex..<sentence.endIndex) { tokenRange, _ in
                    let word = String(sentence[tokenRange]).lowercased()
                    wordFrequency[word, default: 0] += 1
                    return true
                }
            }

            // Score each sentence
            var sentenceScores: [(String, Double)] = []
            for sentence in sentences {
                tokenizer.string = sentence
                var score: Double = 0
                var wordCount = 0

                tokenizer.enumerateTokens(in: sentence.startIndex..<sentence.endIndex) { tokenRange, _ in
                    let word = String(sentence[tokenRange]).lowercased()
                    score += Double(wordFrequency[word] ?? 0)
                    wordCount += 1
                    return true
                }

                if wordCount > 0 {
                    sentenceScores.append((sentence, score / Double(wordCount)))
                }
            }

            // Get top sentences (around 30% of original)
            let numSentences = max(1, sentences.count / 3)
            let topSentences = sentenceScores
                .sorted { $0.1 > $1.1 }
                .prefix(numSentences)
                .map { $0.0 }

            // Maintain original order
            let orderedSummary = sentences.filter { topSentences.contains($0) }

            var output = "Summary:\n\n"
            output += orderedSummary.joined(separator: ". ") + "."
            output += "\n\n---\n"
            output += "Original: \(sentences.count) sentences\n"
            output += "Summary: \(orderedSummary.count) sentences\n"
            output += "Compression: \(String(format: "%.0f%%", Double(orderedSummary.count) / Double(sentences.count) * 100))"

            return output
        }.value
    }
}

// MARK: - Language Task

enum LanguageTask: String, CaseIterable, Identifiable {
    case sentiment = "Sentiment"
    case entities = "Entities"
    case language = "Language"
    case tokenize = "Tokenize"
    case lemmatize = "Lemmatize"
    case summarize = "Summarize"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sentiment: return "face.smiling"
        case .entities: return "person.text.rectangle"
        case .language: return "globe"
        case .tokenize: return "text.word.spacing"
        case .lemmatize: return "textformat.abc"
        case .summarize: return "doc.text"
        }
    }

    var placeholder: String {
        switch self {
        case .sentiment:
            return "Enter text to analyze its emotional tone..."
        case .entities:
            return "Enter text containing names, places, or organizations..."
        case .language:
            return "Enter text in any language to detect..."
        case .tokenize:
            return "Enter text to break down into tokens..."
        case .lemmatize:
            return "Enter text to find base forms of words..."
        case .summarize:
            return "Enter a longer text to generate a summary..."
        }
    }
}
