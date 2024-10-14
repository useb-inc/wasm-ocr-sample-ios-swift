//
//  OcrResponse.swift
//  wasm-ocr-sample-ios-swift
//
//  Created by junsu on 10/10/24.
//

import Foundation

class Review_result {
    var ocr_masking_image: Data?
    var ocr_origin_image: Data?
    
    init(dictionary: [AnyHashable : Any]) {
        let ocr_origin_image_string = dictionary["ocr_origin_image"] as? String
        let originLines = ocr_origin_image_string?.components(separatedBy: ",")
        ocr_origin_image = Data(base64Encoded: originLines?[1] ?? "")

        let ocr_masking_image_string = dictionary["ocr_masking_image"] as? String
        let maskingLines = ocr_masking_image_string?.components(separatedBy: ",")
        ocr_masking_image = Data(base64Encoded: maskingLines?[1] ?? "")
    }
}

class OcrResponse {
    var result: String?
    var review_result: Review_result?

    init(dictionary: [AnyHashable : Any]) {
        let dictionary = dictionary as! [String: Any]
        
        self.result = dictionary["result"] as? String
        self.review_result = Review_result(dictionary: dictionary["review_result"] as? [AnyHashable : Any] ?? [:])
    }

    class func parsingJson(_ jsonString: String?) -> OcrResponse? {
        guard let string = jsonString else {
            print("OCR 결과 정보 분석중 오류가 발생했습니다. Error: jsonString is nil")
            return nil
        }
        guard let uriDecodedData = string.data(using: .utf8) else {
            print("OCR 결과 정보 분석중 오류가 발생했습니다. Error: uriDecodedData is nil")
            return nil
        }
        
        do {
            let jsonDictionary = try JSONSerialization.jsonObject(with: uriDecodedData, options: .mutableContainers)
            let response = OcrResponse(dictionary: jsonDictionary as? [AnyHashable : Any] ?? [:])
            return response
        } catch {
            print("OCR 결과 정보 분석중 오류가 발생했습니다. Error: \(error.localizedDescription)")
            return nil
        }
    }
}
