import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .image

    enum Tab: String, CaseIterable {
        case image = "Image Model"
        case language = "Language Model"

        var icon: String {
            switch self {
            case .image: return "photo.artframe"
            case .language: return "text.bubble"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ImageModelView()
                .tabItem {
                    Label(Tab.image.rawValue, systemImage: Tab.image.icon)
                }
                .tag(Tab.image)

            LanguageModelView()
                .tabItem {
                    Label(Tab.language.rawValue, systemImage: Tab.language.icon)
                }
                .tag(Tab.language)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MLModelManager())
}
