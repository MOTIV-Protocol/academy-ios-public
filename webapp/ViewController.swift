import UIKit
import Firebase
import WebKit
import Foundation
import Alamofire

let REFRESH_TIMEOUT_THRESHOLD = 5
class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    var webView: WKWebView!
    var progressBar: UIProgressView!
    let barColor = UIColor(string: "#3D0135")
    var team_id: String? = nil
    var shortLink: URL? = nil
    
    private var background_start_date = Date()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
     if #available(iOS 13.0, *){
       return .darkContent
     }else{
       return .default
     }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: nil) { [weak self] n in
            self?.background_start_date = Date()
        }
        
        NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: nil) { [weak self] n in
            guard let backgroundStartDate = self?.background_start_date else { return }
            let currentDate = Date()
            let components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: backgroundStartDate, to: currentDate)
            
            if (components.minute! >= REFRESH_TIMEOUT_THRESHOLD){
                self?.webView.load(URLRequest(url: URL(string: "\(Constant.baseURL)?platform=ios")!));
            }
        }
        
        let config = WKWebViewConfiguration()
        config.userContentController = {
            $0.add(self, name: "callbackHandler")
            $0.add(self, name: "registerSessionId")
            return $0
        }(WKUserContentController())
        
        progressBar = UIProgressView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 3))
        progressBar.backgroundColor = .black
        progressBar.progressTintColor = .green
        progressBar.trackTintColor = .black
        
        self.view.addSubview(progressBar)
        let menuHeight: CGFloat = 0
        
        webView = WKWebView(frame: CGRect(x: 0, y: 20, width: self.view.frame.width, height: self.view.frame.height - menuHeight - 20), configuration: config)
        
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil) //
        print(" \(self.view.frame.width) \(self.view.frame.height)")
        
        
        let urlRequest = URLRequest(url: URL(string: "\(Constant.baseURL)?platform=ios")!);
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.load(urlRequest);
        
        webView.scrollView.bounces = false
        webView.scrollView.backgroundColor = .white

        
        self.view.addSubview(webView)
        
//        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
//        if statusBar.responds(to: #selector(setter: UIView.backgroundColor)) {
//            statusBar.backgroundColor = UIColor.white
//        }
    }
    
    

    func showToast(message : String) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 200, height: 80))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 9.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.5, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") { // listen to changes and updated view
            progressBar.isHidden = webView.estimatedProgress == 1
            progressBar.setProgress(Float(webView.estimatedProgress), animated: true)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "callbackHandler":
            guard let userId = message.body as? String, let token = Utils.getUserValue("token") else { return }
            Utils.setUserValue("userId", userId)
            let url = "\(Constant.baseURL)/users/\(userId)/token?token=\(token)&device_type=ios&session_id=\(Utils.getUserValue("sessionId")!)"
            DispatchQueue.global().async {
                Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default).response { d in
                }
            }
        case "registerSessionId":
            guard let sessionId = message.body as? String else { return }
            Utils.setUserValue("sessionId", sessionId)
        default:
            ()
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard webView == self.webView else {
            decisionHandler(.allow)
            return
        }

        let app:UIApplication = UIApplication.shared
        let url:URL = navigationAction.request.url!
        print("webview open \(url)")
        if (url.scheme != "http" && url.scheme != "https" && url.scheme != "about" && url.scheme != "javascript") {
            print("webview open scheme \(String(describing: url.scheme))")
            app.openURL(url)
            decisionHandler(.cancel)
            return
        } else if url.host == "itunes.apple.com" {
            print("url is itunes")
            app.openURL(url)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message, message: nil,
                                                preferredStyle: UIAlertControllerStyle.alert);
        
        alertController.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.cancel) {
            _ in completionHandler()}
        );
        
        self.present(alertController, animated: true, completion: {});
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "네", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        
        alertController.addAction(UIAlertAction(title: "아니오", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        present(alertController, animated: true) {
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(code: Int) {
        self.init(red:(code >> 16) & 0xff, green:(code >> 8) & 0xff, blue:code & 0xff)
    }
    
    convenience init(string: String) {
        let hex = string.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
