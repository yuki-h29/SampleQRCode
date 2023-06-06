//
//  ViewController.swift
//  SampleQRCode
//
//  Created by 平野裕貴 on 2023/06/05.
//

import UIKit
import Photos
import AVFoundation

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton()
        button.backgroundColor = .orange
        button.frame = CGRect(x: UIScreen.main.bounds.width/3, y: 200, width: UIScreen.main.bounds.width/3, height: 50)
        button.setTitle("カメラ起動", for: .normal)
        button.addTarget(self, action: #selector(tapedAudio), for: .touchUpInside)
        view.addSubview(button)
    }
}

// ボタンアクションに関連するメソッドをextensionで分離
extension MainViewController {
    // ボタンアクション
    @objc func tapedAudio(sender: UIButton) {
        self.present(AudioViewController(), animated: true, completion: nil)
    }
}

// カメラ利用の承認申請アラート表示メソッドをextensionで分離
extension MainViewController {
    func allowedRequestStatus() -> Bool{
        var avState = false
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            avState = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                DispatchQueue.main.async {
                    avState = granted
                }
            })
        default:
            avState =  false
        }
        return avState
    }
}
