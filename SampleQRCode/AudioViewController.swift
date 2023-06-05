//
//  AudioViewController.swift
//  SampleQRCode
//
//  Created by 平野裕貴 on 2023/06/05.
//
import UIKit
import Photos
import AVFoundation

class AudioViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    let photoView:UIImageView! = UIImageView() // カメラ画面を表示するためのImageView
    let codeLabel:UILabel! = UILabel()         // 読取結果を表示するためのラベル
    let readingArea = UIView()                 // 読取エリアを示すビュー
    
    // MARK: - AVFoundation
    var avSession: AVCaptureSession!           // カメラなどのデバイスを管理するセッション
    var avInput: AVCaptureDeviceInput!         // カメラ入力を管理
    var avOutput: AVCapturePhotoOutput!        // カメラ出力を管理
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // カメラ画面をフルスクリーンで表示
        photoView.frame = CGRect(x: 0 ,y:0, width: UIScreen.main.bounds.width , height: UIScreen.main.bounds.height)
        self.view.addSubview(photoView)
        
        // カメラの使用許可がある場合、カメラをセットアップ
        if allowedStatus() {
            setupAVCapture()
        }
        
        // 読取エリアを可視化
        readingArea.layer.borderWidth = 2
        readingArea.layer.borderColor = UIColor.orange.cgColor
        view.addSubview(readingArea)
        
        // 結果表示エリアのセットアップ
        codeLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 120, width: UIScreen.main.bounds.width, height: 60)
        codeLabel.backgroundColor = UIColor.gray
        codeLabel.textAlignment = .center
        codeLabel.text = "placeholder"
        self.view.addSubview(codeLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 読取エリアの位置とサイズを設定
        let areaX: CGFloat = view.frame.size.width * 0.2
        let areaY: CGFloat = view.frame.size.height * 0.2
        let areaWidth: CGFloat = view.frame.size.width * 0.6
        let areaHeight: CGFloat = view.frame.size.width * 0.6
        readingArea.frame = CGRect(x: areaX, y: areaY, width: areaWidth, height: areaHeight)
        
        // プレビューレイヤーがある場合、その読取エリアを更新
        if let previewLayer = self.view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            let transformedRect = previewLayer.metadataOutputRectConverted(fromLayerRect: readingArea.frame)
            if let metadataOutput = self.avSession.outputs.first(where: { $0 is AVCaptureMetadataOutput }) as? AVCaptureMetadataOutput {
                metadataOutput.rectOfInterest = transformedRect
            }
        }
    }
    
    // カメラの使用許可状態をチェック
    func allowedStatus() -> Bool{
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            return true
        }else{
            return false
        }
    }
    
    // カメラのセットアップ
    func setupAVCapture() {
        // AVCaptureSessionのインスタンスを作成
        self.avSession = AVCaptureSession()
        
        // デフォルトのビデオデバイスを取得
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            // デバイスから入力を作成
            let deviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            // セッションに入力を追加できる場合は追加する
            if self.avSession.canAddInput(deviceInput) {
                self.avSession.addInput(deviceInput)
                self.avInput = deviceInput
                
                // メタデータ出力を作成
                let metadataOutput = AVCaptureMetadataOutput()
                
                // セッションに出力を追加できる場合は追加する
                if self.avSession.canAddOutput(metadataOutput) {
                    self.avSession.addOutput(metadataOutput)
                    
                    // メタデータ出力のデリゲートを設定し、メタデータタイプを指定する
                    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    metadataOutput.metadataObjectTypes = [.ean13, .qr]
                    
                    // プレビューレイヤーを作成し、ビデオのサイズと位置を設定する
                    let previewLayer = AVCaptureVideoPreviewLayer(session: self.avSession)
                    previewLayer.frame = self.photoView.bounds
                    previewLayer.videoGravity = .resizeAspectFill
                    
                    // プレビューレイヤーをviewのレイヤーに挿入する
                    self.view.layer.insertSublayer(previewLayer, at: 0)
                    
                    // セッションを開始する
                    self.avSession.startRunning()
                }
            }
        } catch {
            // エラーハンドリング
            print(error.localizedDescription)
        }
    }
    
    // メタデータが出力されたときに呼ばれるデリゲートメソッド
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // 出力されたメタデータオブジェクトをループで処理する
        for metadata in metadataObjects as! [AVMetadataMachineReadableCodeObject] {
            // メタデータに文字列が含まれていない場合はスキップ
            if metadata.stringValue == nil { continue }
            
            // メタデータの文字列をラベルに設定
            codeLabel.text = metadata.stringValue!
            
            // メタデータのタイプと値を出力
            print(metadata.type)
            print(metadata.stringValue!)
        }
    }
}
