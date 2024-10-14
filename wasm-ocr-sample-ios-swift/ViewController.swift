//
//  ViewController.swift
//  wasm-ocr-sample-ios-swift
//
//  Created by junsu on 10/10/24.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func ocrButtonPressed(_ sender: UIButton) {
        guard let webVC = storyboard?.instantiateViewController(withIdentifier: "webView") as? WebViewController else {
            print("ViewController 없습니다.")
            return
        }
        webVC.ocrType = OcrType(rawValue: sender.tag)
        
        navigationController?.pushViewController(webVC, animated: false)
    }
}

