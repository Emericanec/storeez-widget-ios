//
//  Storeez_Widget.swift
//  Storeez Widget
//
//  Created by a.svetlichniy on 25.01.2024.
//
import SwiftUI
import WebKit

struct StoreezStory: Codable {
    let id: String
    let url: String
    let title: String
    let previewUrl: String
}

struct StoreezWidgetData: Codable {
    let stories: [StoreezStory]
}

struct StoreezWebView: View {
    @Binding var url: String
    
    var body: some View {
        StoreezWebViewWrapper(url: URL(string: url)!).onAppear{
            print(url)
        }
    }
}

struct StoreezWebViewWrapper: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct StoreezWidget: View {
    let widgetId: String
    let imageWidth: CGFloat = 100
    let imageHeight: CGFloat = 100
    let textWidth: CGFloat = 100
    @State private var items: [StoreezStory] = []
    @State private var isWebViewPresented = false
    @State private var selectedStoryURL: String = "https://google.com"
        
    var body: some View {
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
                                Image(systemName: "ico_placeholder")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: imageWidth, height: imageHeight, alignment: .center)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.blue, lineWidth: 2)
                                    )
                                    .padding(10)
                                    .onTapGesture {
                                        selectedStoryURL = item.url
                                        isWebViewPresented = true
                                    }
                            } else {
                                Image(systemName: "ico_placeholder")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: imageWidth, height: imageHeight, alignment: .center)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.blue, lineWidth: 2)
                                    )
                                    .padding(10)
                                    .onTapGesture {
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
            StoreezWebView(url: $selectedStoryURL)
        }
        .onAppear {
            StoreezApi().getWidgetFromAPI(widgetId: self.widgetId) { stories in
                self.items = stories!
            }
        }
    }

}

class StoreezApi {
    func getWidgetFromAPI(widgetId: String, completion: @escaping ([StoreezStory]?) -> Void) {
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