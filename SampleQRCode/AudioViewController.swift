//
//  AudioViewController.swift
//  SampleQRCode
//
//  Created by 平野裕貴 on 2023/06/05.
//
import UIKit
import Photos
import AVFoundation

class AudioViewController: UIViewController {
    
    let photoView:UIImageView! = UIImageView()
    let codeLabel:UILabel! = UILabel()
    let readingArea = UIView()
    var avSession: AVCaptureSession!
    var avInput: AVCaptureDeviceInput!
    var avOutput: AVCapturePhotoOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoView.frame = CGRect(x: 0 ,y:0, width: UIScreen.main.bounds.width , height: UIScreen.main.bounds.height)
        self.view.addSubview(photoView)
        
        if allowedStatus() {
            setupAVCapture()
        }
        
        readingArea.layer.borderWidth = 2
        readingArea.layer.borderColor = UIColor.orange.cgColor
        view.addSubview(readingArea)
        
        codeLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 120, width: UIScreen.main.bounds.width, height: 60)
        codeLabel.backgroundColor = UIColor.gray
        codeLabel.textAlignment = .center
        codeLabel.text = "placeholder"
        self.view.addSubview(codeLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let areaX: CGFloat = view.frame.size.width * 0.2
        let areaY: CGFloat = view.frame.size.height * 0.2
        let areaWidth: CGFloat = view.frame.size.width * 0.6
        let areaHeight: CGFloat = view.frame.size.width * 0.6
        readingArea.frame = CGRect(x: areaX, y: areaY, width: areaWidth, height: areaHeight)
        
        if let previewLayer = self.view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            let transformedRect = previewLayer.metadataOutputRectConverted(fromLayerRect: readingArea.frame)
            if let metadataOutput = self.avSession.outputs.first(where: { $0 is AVCaptureMetadataOutput }) as? AVCaptureMetadataOutput {
                metadataOutput.rectOfInterest = transformedRect
            }
        }
    }
}

// AVCaptureMetadataOutputObjectsDelegateのデリゲートメソッドをextensionで分離
extension AudioViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for metadata in metadataObjects as! [AVMetadataMachineReadableCodeObject] {
            if metadata.stringValue == nil { continue }
            
            codeLabel.text = metadata.stringValue!
            
            print(metadata.type)
            print(metadata.stringValue!)
        }
    }
}

// カメラの使用許可状態をチェックするメソッドとカメラのセットアップを行うメソッドをextensionで分離
extension AudioViewController {
    func allowedStatus() -> Bool{
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            return true
        }else{
            return false
        }
    }
    
    func setupAVCapture() {
        self.avSession = AVCaptureSession()
        
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if self.avSession.canAddInput(deviceInput) {
                self.avSession.addInput(deviceInput)
                self.avInput = deviceInput
                
                let metadataOutput = AVCaptureMetadataOutput()
                
                if self.avSession.canAddOutput(metadataOutput) {
                    self.avSession.addOutput(metadataOutput)
                    
                    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    metadataOutput.metadataObjectTypes = [.ean13, .qr]
                    
                    let previewLayer = AVCaptureVideoPreviewLayer(session: self.avSession)
                    previewLayer.frame = self.photoView.bounds
                    previewLayer.videoGravity = .resizeAspectFill
                    
                    self.view.layer.insertSublayer(previewLayer, at: 0)
                    
                    self.avSession.startRunning()
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
