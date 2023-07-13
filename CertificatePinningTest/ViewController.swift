//
//  ViewController.swift
//  CertificatePinningTest
//
//  Created by Konstantin Braun on 13.07.23.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        
        let urlRequest = URLRequest(url: URL(string: "https://www.googletagmanager.com")!)
        
        webView.load(urlRequest)
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                      URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
            return
        }
        
        var secresult: CFError?
        let status = SecTrustEvaluateWithError(serverTrust, &secresult)
        
        guard status,
           let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverCertificateData = SecCertificateCopyData(serverCertificate)
        let data = CFDataGetBytePtr(serverCertificateData);
        let size = CFDataGetLength(serverCertificateData);
        let cert1 = NSData(bytes: data, length: size)
        let file_der = Bundle.main.path(forResource: "*.google-analytics.com", ofType: "cer")
        
        if let file = file_der,
           let cert2 = NSData(contentsOfFile: file),
           cert1.isEqual(to: cert2 as Data) {
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
            return
        }
        
        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
    }
}

