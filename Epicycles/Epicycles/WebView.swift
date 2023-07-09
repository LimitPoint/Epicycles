//
//  WebView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/26/23.
//

import SwiftUI
import WebKit

struct WebAlertInfo: Identifiable {
    
    enum AlertType {
        case clearHistory
        case downloadNotSupported
        case webPageNavigationFailed
    }
    
    let id: AlertType
    let title: String
    let message: String
}

/*
 Be sure to select 'Outgoing Connections (Client)' in 'Signing & Capabilities'
 */

class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var webView: WKWebView?
    @Published var canGoBack = false
    @Published var canGoForward = false
    
    weak var observableObject: WebViewObservableObject?
    
        // Function to go back in browsing history
    func goBack() {
        guard let webView = webView, webView.canGoBack else {
            return
        }
        webView.goBack()
    }
    
        // Function to go forward in browsing history
    func goForward() {
        guard let webView = webView, webView.canGoForward else {
            return
        }
        webView.goForward()
    }
    
        // WKNavigationDelegate methods
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            self?.canGoBack = webView.canGoBack
            self?.canGoForward = webView.canGoForward
        }
    }
    
        // WKNavigationDelegate method: called when a page starts loading
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        observableObject?.updateHistory(with: url)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
                // Check if the URL is a download link
            if navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame {
                let userInfo = ["url": url]
                NotificationCenter.default.post(name: Notification.Name("DownloadNotSupported"), object: nil, userInfo: userInfo)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NotificationCenter.default.post(name: Notification.Name("WebPageNavigationFailed"), object: nil, userInfo: nil)
    }
}

struct VisitedURL: Hashable {
    let id = UUID()
    let url: URL
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: VisitedURL, rhs: VisitedURL) -> Bool {
        lhs.id == rhs.id
    }
}

class WebViewObservableObject: ObservableObject {
    @Published var isWebViewPresented = false
    @Published var urlString: String = ""
    @Published var canGoBack = false
    @Published var canGoForward = false
    let coordinator: WebViewCoordinator
    
    @Published var visitedURLs: [VisitedURL] = [] // Track visited URLs
    
    init(urlString: String) {
        
        self.urlString = urlString
        self.coordinator = WebViewCoordinator()
        
            // Observe changes in coordinator's properties
        coordinator.$canGoBack.receive(on: DispatchQueue.main).assign(to: &$canGoBack)
        coordinator.$canGoForward.receive(on: DispatchQueue.main).assign(to: &$canGoForward)
        
    }
    
        // Function to go back in browsing history
    func goBack() {
        coordinator.goBack()
    }
    
        // Function to go forward in browsing history
    func goForward() {
        coordinator.goForward()
    }
    
    func reloadOriginal() {
        guard let webView = coordinator.webView else {
            return
        }
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func navigate(to url: URL) {
        guard let webView = coordinator.webView else {
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
        // Function to update the visited URL history
    func updateHistory(with url: URL) {
        visitedURLs.append(VisitedURL(url: url))
    }
    
        // Function to clear the browsing history
    func clearHistory() {
        visitedURLs.removeAll()
    }
    
    func currentURL() -> String {
        
        if let url = coordinator.webView?.url {
            return url.absoluteString
        }
        
        return ""
    }
}

#if os(iOS)

struct WebViewiOS: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewObservableObject
    
    func makeUIView(context: Context) -> WKWebView {
        guard let url = URL(string: viewModel.urlString) else {
            return WKWebView()
        }
        let request = URLRequest(url: url)
        let webView = WKWebView()
        webView.navigationDelegate = viewModel.coordinator
        webView.load(request)
        viewModel.coordinator.webView = webView // Assign the webView to the coordinator
        viewModel.coordinator.observableObject = viewModel // Set the coordinator's observableObject for updating its history
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#elseif os(macOS)

struct WebViewMac: NSViewRepresentable {
    @ObservedObject var viewModel: WebViewObservableObject
    
    func makeNSView(context: Context) -> WKWebView {
        guard let url = URL(string: viewModel.urlString) else {
            return WKWebView()
        }
        let request = URLRequest(url: url)
        let webView = WKWebView()
        webView.navigationDelegate = viewModel.coordinator
        webView.load(request)
        viewModel.coordinator.webView = webView // Assign the webView to the coordinator
        viewModel.coordinator.observableObject = viewModel // Set the coordinator's observableObject for updating its history
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif

struct WebView: View {
    @ObservedObject var webViewModel:WebViewObservableObject
    
    @State var webAlertInfo: WebAlertInfo?
    @State var urlForDownload:URL?
    
    var urlBar: some View {
        
        HStack {
            if let url = URL(string: kEpicyclesURL) {
                Button(action: {
                    webViewModel.navigate(to: url)
                }) {
                    Text("Epicycles")
                }
                .foregroundColor(.blue)
                .buttonStyle(PlainButtonStyle())
            }
            
            Text("|")
            
            if let url = URL(string: kEulersFormulaURL) {
                Button(action: {
                    webViewModel.navigate(to: url)
                }) {
                    Text("Euler's Formula")
                }
                .foregroundColor(.blue)
                .buttonStyle(PlainButtonStyle())
            }
            
            Text("|")
            
            if let url = URL(string: kFourierSeriesURL) {
                Button(action: {
                    webViewModel.navigate(to: url)
                }) {
                    Text("Fourier Series")
                }
                .foregroundColor(.blue)
                .buttonStyle(PlainButtonStyle())
            }
                
        }
        
    }
    
    var historyBar: some View {
        HStack {
            Button(action: {
                webViewModel.reloadOriginal()
            }) {
                HStack {
                    Image(systemName: "house")
                }
            }
            
            Spacer()
            
            Menu {
                ForEach(webViewModel.visitedURLs, id: \.id) { visitedURL in
                    Button(action: {
                        webViewModel.navigate(to: visitedURL.url)
                    }) {
                        Text(visitedURL.url.absoluteString)
                    }
                }
            } label: {
                Label("History", systemImage: "clock")
            }
            .id(UUID()) // Menu not displaying - Add this by suggestion : https://developer.apple.com/forums/thread/692338
            
            Spacer()
            
            Button(action: {
                webAlertInfo = WebAlertInfo(id: .clearHistory, title: "Clear History", message: "Are you sure you want to clear the browsing history?")
            }) {
                Image(systemName: "trash")
            }
        }
        
    }
    
    var navBar: some View {
        HStack {
            Spacer()
            
            Button(action: {
                webViewModel.goBack()
            }) {
                    //Text("Back")
                Image(systemName: "chevron.left")
            }
            .disabled(webViewModel.canGoBack == false)
            
            Spacer()
            
            Button(action: {
                webViewModel.goForward()
            }) {
                    //Text("Forward")
                Image(systemName: "chevron.right")
            }
            .disabled(webViewModel.canGoForward == false)
            
            Spacer()
        }
    }
    
    var browserView: some View {
#if os(iOS)
        WebViewiOS(viewModel: webViewModel)
#elseif os(macOS)
        WebViewMac(viewModel: webViewModel)
#endif   
    }
    
    func openURL(_ urlString:String) {
        
        guard let url = URL(string: urlString) else {
            return
        }
#if os(iOS)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
#elseif os(macOS)
        NSWorkspace.shared.open(url)
#endif
    }
    
    var body: some View {
        VStack {
            
            Button(action: {
                webViewModel.isWebViewPresented = false
            }) {
                Text("Done")
            }
            .padding(.top)
            
            historyBar
                .padding()
            
            urlBar
                .padding()
            
            Button(action: {
                openURL(webViewModel.currentURL())
            }) {
                Text("\(webViewModel.currentURL())")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            browserView
            
            navBar
                .padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DownloadNotSupported"))) { notification in
            if let url = notification.userInfo?["url"] as? URL {
                urlForDownload = url
            }
            webAlertInfo = WebAlertInfo(id: .downloadNotSupported, title: "Download Not Supported", message: "Access in your default web browser with the link button above.")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WebPageNavigationFailed"))) { _ in
            webAlertInfo = WebAlertInfo(id: .webPageNavigationFailed, title: "Link Unavailable", message: "Access in your default web browser with the link button above.")
        }
        .alert(item: $webAlertInfo, content: { webAlertInfo in
            switch webAlertInfo.id {
                case .clearHistory:
                    return Alert(title: Text(webAlertInfo.title),
                                 message: Text(webAlertInfo.message),
                                 primaryButton: .default(Text("Yes")) {  webViewModel.clearHistory()}, 
                                 secondaryButton: .cancel(Text("No")) { })
                case .downloadNotSupported:
                    return Alert(title: Text(webAlertInfo.title),
                                 message: Text(webAlertInfo.message),
                                 dismissButton: .default(Text("OK")))
                case .webPageNavigationFailed:
                    return Alert(title: Text(webAlertInfo.title),
                                 message: Text(webAlertInfo.message),
                                 dismissButton: .default(Text("OK")))
            }
        })
    }
} 

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(webViewModel: WebViewObservableObject(urlString: kFourierSeriesURL))
    }
}
