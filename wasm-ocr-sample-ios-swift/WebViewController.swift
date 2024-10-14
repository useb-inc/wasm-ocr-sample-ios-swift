//
//  WebViewController.swift
//  wasm-ocr-sample-ios-swift
//
//  Created by junsu on 10/10/24.
//

import UIKit
import AVFoundation
import WebKit

class WebViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    var webView: WKWebView?
    var ocrType: OcrType?
    var responseName: String?
    var result: String?
    var responseJson: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "OCR"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCameraPerssion()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // View 불러오기
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.preferences.javaScriptEnabled = true
        
        // OCR 정보를 담은 postMessage 설정
        guard let requestData = encodedPostMessage() else { return }
        let jsScript = "setTimeout(function() { usebwasmocrreceive('\(requestData)'); }, 500);"
        let userScript = WKUserScript(source: jsScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webConfiguration.userContentController.addUserScript(userScript)
        
        
        // 메시지 수신할 핸들러 등록
        // web에서 호출할 펑션이름 webkit.messageHandlers.{AppFunction}.postMessage("원하는 데이터")
        responseName = "usebwasmocr"
        webConfiguration.userContentController.add(self, name: responseName ?? "")
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView?.uiDelegate = self
        
#if DEBUG
        if #available(iOS 16.4, *) {
            webView?.isInspectable = true
        }
#endif
        self.view = webView
    }
    
    // WebView 불러오기
    func loadWebView() {
        guard let url = URL(string: "https://ocr.useb.co.kr/ocr.html") else { return }
        let request = URLRequest(url: url)
        
        webView?.load(request)
    }
    
    // OCR 결과 창으로 이동
    func loadReportView() {
        guard let reportVC = storyboard?.instantiateViewController(withIdentifier: "reportView") as? ReportViewController else {
            print("ViewController 없습니다.")
            return
        }
        
        reportVC.ocrType = ocrType
        reportVC.result = result
        reportVC.responseJson = responseJson
        
        navigationController?.pushViewController(reportVC, animated: false)
    }
    
    // webView Javascript Alert 처리
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "확인", style: .cancel) { _ in
            completionHandler()
        }
        
        alertController.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.name != responseName) { return }
        guard let messageBody = message.body as? String else { return }
        
        guard let decodedMessage = decodedPostMessage(encodedMessage: messageBody) else {
            print("OCR 응답 메시지 분석에 실패했습니다.")
            return
        }
        
        guard let ocrResponse = OcrResponse.parsingJson(decodedMessage) else {
            print("OCR 응답 메시지 변환에 실패했습니다.")
            return
        }
        
        result = ocrResponse.result
        
        if ocrResponse.result == "success" {
            print("OCR 작업이 성공했습니다.")
            responseJson = decodedMessage
        } else if ocrResponse.result == "failed" {
            print("OCR 작업이 실패했습니다.")
            responseJson = decodedMessage
        } else if ocrResponse.result == "error" {
            print("오류가 발생했습니다. \(decodedMessage)")
            responseJson = decodedMessage;
        } else {
            print("유효하지 않은 결과입니다. \(ocrResponse.result ?? "")")
            result = nil;
            responseJson = nil;
        }
        
        loadReportView()
    }
    
    func checkCameraPerssion() {
        let permission = AVCaptureDevice.authorizationStatus(for: .video)
        switch permission {
        case .authorized:
            DispatchQueue.main.async {
                self.loadWebView()
            }
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.loadWebView()
                    }
                } else {
                    print("권한이 거부되었습니다.")
                    self.navigationController?.popViewController(animated: true)
                }
            }
            break
        default:
            print("Permission = \(permission)")
            break
        }
    }
    
    // PostMessage로 보낼 OCR 정보를 생성합니다
    func encodedPostMessage() -> String? {
        let jsonDictionary = [
            "ocrType": ocrTypeToString(),
            "settings": ["licenseKey": ""]
        ] as [String : Any]
        
        // JSON -> encodeURIComponent -> Base64Encoding
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: .withoutEscapingSlashes)
            let jsonString = String(data: jsonData, encoding: .utf8)
            let uriEncoded = jsonString?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            return uriEncoded?.data(using: .utf8)?.base64EncodedString(options: .endLineWithLineFeed)
        } catch {
            NSLog("OCR 정보 생성에 실패했습니다. Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // OCR 수행 결과를 분석합니다.
    func decodedPostMessage(encodedMessage: String) -> String? {
        // Base64Decoding -> decodeURIComponent -> JSON
        guard let base64DecodedData = Data(base64Encoded: encodedMessage, options: .ignoreUnknownCharacters) else { return nil }
        guard let base64DecodedString = String(data: base64DecodedData, encoding: .utf8) else { return nil }
        let jsonString = base64DecodedString.removingPercentEncoding
        return jsonString
    }
    
    // OCR 종류를 String으로 변환
    func ocrTypeToString() -> String {
        guard let ocrType = ocrType else { return "" }
        switch ocrType {
        case .idcard:
            return "idcard"
        case .passport:
            return "passport"
        case .alien:
            return "alien"
        case .credit:
            return "credit"
        case .idcard_ssa:
            return "idcard-ssa"
        case .passport_ssa:
            return "passport-ssa"
        case .alien_ssa:
            return "alien-ssa"
        }
    }
}

