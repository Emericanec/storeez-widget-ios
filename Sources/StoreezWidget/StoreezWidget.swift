// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftUI
import WebKit

#if os(iOS)
public struct StoreezStory: Codable {
    let id: String
    let url: String
    let title: String
    let previewUrl: String
}

struct StoreezWidgetData: Codable {
    let stories: [StoreezStory]
}

@available(macOS 15.00, *)
 struct StoreezWebView: View {
    @Binding var url: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                StoreezWebViewWrapper(url: URL(string: url)!)
            }
            .navigationBarItems(trailing: Button(action: {
                isPresented = false
            }, label: {
                Text("Close")
            }))
        }
        
    }
}

@available(macOS 15.00, *)
public struct StoreezWebViewWrapper: UIViewRepresentable {
    let url: URL
    
    public func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.load(URLRequest(url: url))
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

@available(macOS 15.00, *)
struct StoreezImagePlaceholder: View {
    let imageWidth: CGFloat = 100
    let imageHeight: CGFloat = 100
    let imageStrokeColor: Color = Color.blue
    
    @available(macOS 15.00, *)
    var body: some View {
        Image(systemName: "ico_placeholder")
            .resizable()
            .scaledToFill()
            .frame(width: imageWidth, height: imageHeight, alignment: .center)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(imageStrokeColor, lineWidth: 2)
            )
            .padding(10)
    }
}

@available(macOS 15.00, *)
public struct StoreezWidget: View {
    let widgetId: String
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let imageStrokeColor: Color
    let textWidth: CGFloat
    @State private var items: [StoreezStory] = []
    @State private var isWebViewPresented = false
    @State private var selectedStoryURL: String = "https://google.com"
    
    public init(widgetId: String, imageWidth: CGFloat = 100, imageHeight: CGFloat = 100, imageStrokeColor: Color = Color.blue, textWidth: CGFloat = 100) {
        self.widgetId = widgetId
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageStrokeColor = imageStrokeColor
        self.textWidth = textWidth
    }
        
    public var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(items, id: \.id) { item in
                    VStack {
                        AsyncImage(url: URL(string: item.previewUrl)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100, alignment: .center)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.blue, lineWidth: 2)
                                    )
                                    .padding(10)
                                    .clipped()
                                    .onTapGesture {
                                        selectedStoryURL = item.url
                                        isWebViewPresented = true
                                    }
                            } else if phase.error != nil {
                                StoreezImagePlaceholder()
                                    .onTapGesture {
                                        selectedStoryURL = item.url
                                        isWebViewPresented = true
                                    }
                            } else {
                                StoreezImagePlaceholder().onTapGesture {
                                        selectedStoryURL = item.url
                                        isWebViewPresented = true
                                    }
                            }
                        }
                        Text(item.title)
                            .frame(width: textWidth, alignment: .center)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .onTapGesture {
                                selectedStoryURL = item.url
                                isWebViewPresented = true
                            }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isWebViewPresented) {
            StoreezWebView(url: $selectedStoryURL, isPresented: $isWebViewPresented)
        }
        .onAppear {
            StoreezApi().getWidgetFromAPI(widgetId: self.widgetId) { stories in
                self.items = stories!
            }
        }
    }

}

public class StoreezApi {
    public func getWidgetFromAPI(widgetId: String, completion: @escaping ([StoreezStory]?) -> Void) {
        if let url = URL(string: "https://api.storeez.app/widget/" + widgetId) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(StoreezWidgetData.self, from: data)
                        DispatchQueue.main.async {
                            completion(decodedResponse.stories)
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                        completion(nil)
                    }
                }
            }.resume()
        }
    }
}
#endif
