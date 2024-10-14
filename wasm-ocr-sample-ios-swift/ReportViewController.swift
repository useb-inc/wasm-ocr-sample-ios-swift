//
//  ReportViewController.swift
//  wasm-ocr-sample-ios-swift
//
//  Created by junsu on 10/10/24.
//

import UIKit

class ReportViewController: UIViewController {
    @IBOutlet weak var txtEvent: UITextView!
    @IBOutlet weak var txtDetail: UITextView!
    @IBOutlet weak var lblOcrType: UILabel!
    @IBOutlet weak var imgIdMasking: UIImageView!
    @IBOutlet weak var imgIdOrigin: UIImageView!
    
    let alcheraColor = UIColor(named: "alcheraColor")
    var ocrType: OcrType?
    var result: String?
    var responseJson: String?
    var NOTAVAILABLE = "N/A"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "OCR Report"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        txtEvent.layer.borderWidth = 1
        txtEvent.layer.borderColor = alcheraColor?.cgColor
        txtEvent.text = result
        
        txtDetail.text = prettyPrintedJson(responseJson ?? "")
        txtDetail.layer.borderWidth = 1
        txtDetail.layer.borderColor = alcheraColor?.cgColor
        
        lblOcrType.text = ocrTypeToString()
        
        drawResponse()
    }
    
    // 완료 버튼 클릭
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popToRootViewController(animated: false)
    }
    
    func drawResponse() {
        guard let responseJson = responseJson else { return }
        guard let response = OcrResponse.parsingJson(responseJson) else { return }
        guard let detail = response.review_result else { return }
        guard let imgIdMaskingData = detail.ocr_masking_image else { return }
        guard let imgIdOriginData = detail.ocr_origin_image else { return }
        self.imgIdMasking.image = UIImage(data: imgIdMaskingData)
        self.imgIdOrigin.image = UIImage(data: imgIdOriginData)
    }
    
    func prettyPrintedJson(_ jsonString: String) -> String? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            let prettyString = String(data: prettyData, encoding: .utf8)
            return prettyString
        } catch {
            print("Json 데이터 변환에 실패했습니다. Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func ocrTypeToString() -> String {
        switch self.ocrType {
        case .idcard:
            return "주민등록증/운전면허증"
        case .passport:
            return "국내여권/해외여권"
        case .alien:
            return "외국인등록증"
        case .credit:
            return "신용카드"
        case .idcard_ssa:
            return "주민등록증/운전면허증 + 사본판별"
        case .passport_ssa:
            return "국내여권/해외여권 + 사본판별"
        case .alien_ssa:
            return "외국인등록증 + 사본판별"
        default:
            return "N/A"
        }
    }
}

