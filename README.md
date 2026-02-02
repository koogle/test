# ML Playground

An iOS app for experimenting with on-device machine learning models, supporting both image classification and natural language processing.

## Features

### Image Classification
- **Photo Library Integration**: Select images from your photo library
- **Camera Support**: Capture images directly for real-time classification
- **Vision Framework**: Uses Apple's Vision framework with built-in classification models
- **Custom Models**: Import your own Core ML models (.mlmodel files)
- **Top-5 Results**: See confidence scores for the top 5 predictions

### Language Processing
- **Sentiment Analysis**: Analyze the emotional tone of text
- **Named Entity Recognition**: Extract people, places, and organizations
- **Language Detection**: Identify the language of input text
- **Tokenization**: Break text into individual tokens with frequency analysis
- **Lemmatization**: Find base forms of words
- **Text Summarization**: Generate extractive summaries of longer texts

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Open `MLPlayground/MLPlayground.xcodeproj` in Xcode
2. Select your development team in the project settings
3. Build and run on a device or simulator

## Project Structure

```
MLPlayground/
├── Sources/MLPlayground/
│   ├── MLPlaygroundApp.swift       # App entry point
│   ├── Views/
│   │   ├── ContentView.swift       # Main tab view
│   │   ├── ImageModelView.swift    # Image classification UI
│   │   ├── LanguageModelView.swift # NLP tasks UI
│   │   └── Components/
│   │       └── CameraView.swift    # Camera capture component
│   ├── Services/
│   │   ├── MLModelManager.swift    # Model management
│   │   ├── ImageClassifier.swift   # Image classification service
│   │   └── LanguageProcessor.swift # NLP service
│   └── Resources/
│       ├── Info.plist
│       └── Assets.xcassets/
└── MLPlayground.xcodeproj/
```

## Adding Custom Models

1. Train or download a Core ML model (.mlmodel file)
2. The app will scan the Documents/MLModels directory for custom models
3. Models will appear in the available models list

## Frameworks Used

- **SwiftUI**: Modern declarative UI
- **Core ML**: On-device machine learning
- **Vision**: Image analysis and classification
- **Natural Language**: Text processing and NLP tasks
- **PhotosUI**: Photo library access
- **AVFoundation**: Camera capture

## Privacy

All ML processing happens on-device. No data is sent to external servers.

## License

MIT License
