//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2024/8/8.
//

import UIKit
import AVFoundation
import Photos
import WWDualCamera
import WWScreenRecorder
import WWPrint

// MARK: - ViewController
final class ViewController: UIViewController {
    
    @IBOutlet weak var cameraLayerView: UIView!
    @IBOutlet weak var mainView: UIImageView!
    @IBOutlet weak var subView: UIImageView!
    @IBOutlet weak var recorderButtonItem: UIBarButtonItem!
    @IBOutlet weak var cameraFlashModeButtonItem: UIBarButtonItem!
    @IBOutlet weak var flashlightModeButtonItem: UIBarButtonItem!
    @IBOutlet weak var subViewWidthLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var subViewHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var cameraZoomSegmentedControl: UISegmentedControl!
    
    private let subViewDiameter: CGFloat = 128.0
    private let cameraZoomFactorArray: [CGFloat] = [1.0, 2.0, 5.0]
    
    private var isInitialize = false
    private var isDisplay = true
    private var isMainLayerInBack = true
    private var isRecording = false
    private var isSessionStarted = false
    
    private var zoomFactor = 1.0
    private var torchLevel: Float = 0.0
    private var subLayerNewCenter: CGPoint?
    
    private var currentCameraFlashMode: AVCaptureDevice.FlashMode = .auto
    private var currentSubLayerStyle: Constant.SubLayerStyle = .circle
    private var torchMode: AVCaptureDevice.TorchMode = .off
    
    private var subLayerStyles: [Constant.SubLayerStyle] = []
    private var cameraDevices: [AVCaptureDevice] = []
    private var videoDataOutputs: (back: AVCaptureVideoDataOutput?, front: AVCaptureVideoDataOutput?)
    
    private var photoOutputs: [AVCapturePhotoOutput] = []
    private var _photoOutputs: [AVCapturePhotoOutput] = []
    private var photos: [AVCapturePhoto] = []
    
    private var takePhotoClosure: ((Result<AVCapturePhoto, Error>) -> Void)?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        initViewSetting()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        viewIsAppearingAction()
    }
    
    @IBAction func switchCameraFlash(_ sender: UIBarButtonItem) {
        switchCameraFlashAction()
    }
    
    @IBAction func startRecoding(_ sender: UIBarButtonItem) {
        recodingAction()
    }
    
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        takePhotoAction(flashMode: currentCameraFlashMode)
    }
    
    @IBAction func switchFlashlight(_ sender: UIBarButtonItem) {
        switchFlashlightAction()
    }
    
    @IBAction func cameraZoomSetting(_ sender: UISegmentedControl) {
        cameraZoomFactorSetting(sender: sender)
    }
}

// MARK: - @objc handle
@objc private extension ViewController {
    
    func handlePinchGesture(_ pinch: UIPinchGestureRecognizer) {
        cameraZoomAction(with: pinch)
    }
    
    func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        moveSubLayerAction(with: pan)
    }
    
    func handleSwipeGesture(_ swipe: UISwipeGestureRecognizer) {
        
        switch swipe.direction {
        case .up: recodingAction()
        case .down: switchFlashlightAction()
        case .left: exchangeSubViewStyle()
        case .right: switchDualCameraAction()
        default: break
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension ViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error { takePhotoClosure?(.failure(error)); return }
        
        takePhotoClosure?(.success(photo))
        _photoOutputs.popLast()?._setting(quality: .speed)._capturePhoto(flashMode: currentCameraFlashMode, delegate: self)
    }
}

// MARK: - 主工具
private extension ViewController {
    
    /// 畫面出現後，僅做一次的設定
    func viewIsAppearingAction() {
        
        if (!isInitialize) {
            initSetting()
            startDualCameraAction()
        }
    }
        
    /// 初始化一些畫面的基本設定
    func initViewSetting() {
        view.backgroundColor = .black
        mainView.backgroundColor = .clear
        subView.backgroundColor = .clear
    }
    
    /// 切換相機閃光燈模式
    func switchCameraFlashAction() {
        
        let flashMode = AVCaptureDevice.FlashMode(rawValue: (currentCameraFlashMode.rawValue + 1) % 3) ?? .auto
        switchCameraFlashMode(flashMode)
    }
    
    /// 錄影功能切換
    func recodingAction() {
        !WWScreenRecorder.shared.isRecording ? startRecordingAction() : stopRecordingAction()
    }
    
    /// 拍照功能 => 一張一張照，然後合成同一張 (擷圖)
    /// - Parameter flashMode: 閃光燈設定
    func takePhotoAction(flashMode: AVCaptureDevice.FlashMode) {
        
        displayBarButtonItems(false)
        
        photos = []
        _photoOutputs = photoOutputs
        
        if isMainLayerInBack { _photoOutputs.reverse() }
        _photoOutputs.popLast()?._setting(quality: .speed)._capturePhoto(flashMode: flashMode, delegate: self)
    }
    
    /// 切換相機手電筒模式 (On / Off)
    func switchFlashlightAction() {
        torchMode = (torchMode == .on) ? .off : .on
        switchFlashlightMode(torchMode)
    }
    
    /// 直接設定主相機放大倍率
    /// - Parameter sender: UISegmentedControl
    func cameraZoomFactorSetting(sender: UISegmentedControl) {
        let zoomFactor = cameraZoomFactorArray[sender.selectedSegmentIndex]
        cameraZoomFactor(zoomFactor)
    }
}

// MARK: - 手勢功能
private extension ViewController {
    
    /// 鏡頭雙指縮放功能
    /// - Parameter pinch: UIPinchGestureRecognizer
    func cameraZoomAction(with pinch: UIPinchGestureRecognizer) {
        
        cameraZoomAction(scale: pinch.scale)
        
        switch pinch.state {
        case .began, .changed: pinch.scale = 1.0
        case .ended: break
        case .cancelled, .possible, .failed: break
        @unknown default: fatalError()
        }
    }
    
    /// 移動小鏡頭畫面
    /// - Parameter pan: UIPanGestureRecognizer
    func moveSubLayerAction(with pan: UIPanGestureRecognizer) {
        
        guard let panLocation = Optional.some(pan.translation(in: subView)),
              let view = pan.view
        else {
            return
        }
        
        let newCenter = view.center + panLocation
        
        CALayer._animations(isEnabled: false) { [unowned self] in
            subLayerCenterSetting(newCenter)
        }
        
        pan.setTranslation(.zero, in: pan.view)
    }
    
    /// 切換SubView的外型 (圓形 / 正方形 / 長方形)
    func exchangeSubViewStyle() {
        
        if (subLayerStyles.isEmpty) { subLayerStyles = subLayerStyleMaker() }
        currentSubLayerStyle = subLayerStyles.popLast() ?? .circle
        exchangeSubViewStyleAction(currentSubLayerStyle)
    }
    
    /// 切換前後鏡頭 => previewLayer層對調
    func switchDualCameraAction() {
        
        guard let lastLayer1 = cameraLayerView.layer.sublayers?.popLast() as? AVCaptureVideoPreviewLayer,
              let lastLayer2 = cameraLayerView.layer.sublayers?.popLast() as? AVCaptureVideoPreviewLayer
        else {
            return
        }
        
        UIView._animations(isEnabled: false) { [unowned self] in
            
            lastLayer1.frame = mainView.frame
            lastLayer2.frame = subView.frame

            lastLayer1.cornerRadius = mainView.layer.cornerRadius
            lastLayer2.cornerRadius = subView.layer.cornerRadius
            
            cameraLayerView.layer.addSublayer(lastLayer1)
            cameraLayerView.layer.addSublayer(lastLayer2)
            
            isMainLayerInBack.toggle()
        }
    }
}

// MARK: - 小工具
private extension ViewController {
    
    /// [初始化設定](https://www.swiftwithvincent.com/tips)
    func initSetting() {
        
        initSettingDaulCamera()
        initCapturedDidChangeNotification()
        initTackPhotoSetting()
        initGestureRecognizerSetting()
        
        isInitialize = true
    }
    
    /// 初始化手勢功能
    /// - 單指上滑 => 切換錄影功能 (開 / 關)
    /// - 單指下滑 => 切換相機手電筒模式 (開 / 關)
    /// - 單指右滑 => 切換子視窗大小 (圓形 / 正方形 / 長方形)
    /// - 單指左滑 => 切換前後鏡頭
    /// - 單指移動 => 移動子視窗畫面功能
    /// - 雙指捏合 => 主鏡頭縮放功能
    func initGestureRecognizerSetting() {
        
        let pinchGesture = UIPinchGestureRecognizer._build(target: self, action: #selector(Self.handlePinchGesture(_:)))
        let panGesture = UIPanGestureRecognizer._build(target: self, action: #selector(Self.handlePanGesture(_:)))
        let swipeUpGesture = UISwipeGestureRecognizer._build(target: self, direction: .up, action: #selector(Self.handleSwipeGesture(_:)))
        let swipeDownGesture = UISwipeGestureRecognizer._build(target: self, direction: .down, action: #selector(Self.handleSwipeGesture(_:)))
        let swipeLeftGesture = UISwipeGestureRecognizer._build(target: self, direction: .left, action: #selector(Self.handleSwipeGesture(_:)))
        let swipeRightGesture = UISwipeGestureRecognizer._build(target: self, direction: .right, action: #selector(Self.handleSwipeGesture(_:)))
        
        view.addGestureRecognizer(pinchGesture)
        cameraLayerView.addGestureRecognizer(swipeUpGesture)
        cameraLayerView.addGestureRecognizer(swipeDownGesture)
        cameraLayerView.addGestureRecognizer(swipeLeftGesture)
        cameraLayerView.addGestureRecognizer(swipeRightGesture)
        subView.addGestureRecognizer(panGesture)
    }
    
    /// 初始化設定雙鏡頭參數
    func initSettingDaulCamera() {
        
        let inputs: [WWDualCamera.CameraSessionInput] = [
            (frame: mainView.frame, deviceType: .builtInWideAngleCamera, position: .back),
            (frame: subView.frame, deviceType: .builtInWideAngleCamera, position: .front),
        ]
        
        let sessionOutputs = WWDualCamera.shared.sessionOutputs(delegate: nil, inputs: inputs)
        
        sessionOutputs.forEach { info in
            
            guard let device = info.device,
                  let previewLayer = info.previewLayer,
                  let output = info.output
            else {
                return
            }
            
            switch device.position {
            case .back: videoDataOutputs.back = output
            case .front: videoDataOutputs.front = output
            default: break
            }
            
            cameraLayerView.layer.addSublayer(previewLayer)
            cameraDevices.append(device)
        }
        
        exchangeSubViewStyle()
    }
    
    /// 初始化正在錄影時的反應 (隱藏BarButtonItems)
    func initCapturedDidChangeNotification() {
        
        NotificationCenter.default.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main) { [unowned self] _ in
            displayBarButtonItems(!UIScreen.main.isCaptured)
        }
    }
    
    /// 初始化擷圖相關的設定
    func initTackPhotoSetting() {
        
        photoOutputs = [AVCapturePhotoOutput(), AVCapturePhotoOutput()]
        _ = WWDualCamera.shared.addOutputs(photoOutputs)
        
        takePhotoClosure = { [unowned self] result in
            
            switch result {
            case .failure(let error):
                
                displayBarButtonItems(true)
                presentAlertController(with: "Error", message: "\(error)")
                
            case .success(let photo):
                
                DispatchQueue.main.async { [unowned self] in
                    photos.append(photo)
                    if (photos.count > 1) { storePicture(with: photos) }
                }
            }
        }
    }
    
    /// 顯示BarButtonItems
    /// - Parameter isDisplay: Bool
    func displayBarButtonItems(_ isDisplay: Bool) {
        
        guard let navigationController = self.navigationController else { return }
        
        navigationController.isNavigationBarHidden = (!isDisplay) ? true : false
        self.isDisplay = isDisplay
        
        cameraZoomSegmentedControl.isHidden = navigationController.isNavigationBarHidden
        exchangeSubViewStyleAction(currentSubLayerStyle)
    }
    
    /// 啟動雙鏡頭
    func startDualCameraAction() {
        
        if (!WWDualCamera.shared.isRunning) { _ = WWDualCamera.shared.start(); return }
        _ = WWDualCamera.shared.stop()
    }
        
    /// 開始錄影 (不再自動進入鎖定畫面)
    func startRecordingAction() {
        
        UIApplication.shared._awake(true)
        switchCameraFlashMode(.off)
        
        WWScreenRecorder.shared.start { [unowned self] result in
            
            switch result {
            case .failure(let error): presentAlertController(with: "Error", message: error.localizedDescription)
            case .success(let isSuccess): if (!isSuccess) { presentAlertController(with: "Error", message: "Not Recording!") }
            }
            
            recorderButtonItemSetting()
        }
    }
    
    /// 結束錄影 (回復自動進入鎖定畫面)
    func stopRecordingAction() {
        
        UIApplication.shared._awake(false)
        
        WWScreenRecorder.shared.stop { [unowned self] result in
            
            switch result {
            case .failure(let error): presentAlertController(with: "Error", message: error.localizedDescription)
            case .success(let previewViewController):
                previewViewController.view.tintColor = .systemBlue
                previewViewController._transparent()
                present(previewViewController, animated: true)
            }
            
            recorderButtonItemSetting()
        }
    }
    
    /// 設定recorderButtonItem的圖示
    func recorderButtonItemSetting() {
        recorderButtonItem.image = (!WWScreenRecorder.shared.isRecording) ? UIImage(named: "VideoRecoder") : UIImage(named: "Stop")
    }
    
    /// 彈出訊息AlertController
    /// - Parameters:
    ///   - title: String?
    ///   - message: String?
    func presentAlertController(with title: String?, message: String?) {
        
        let actions: [Constant.AlertActionInformation] = [(title: "OK", style: .default, handler: nil)]
        let alertController = UIAlertController._build(with: title, message: message, actions: actions)
        
        present(alertController, animated: true)
    }
    
    /// 主鏡頭畫面放大縮小功能 (比原來的比例大一點)
    /// - Parameter scale: CGFloat
    func cameraZoomAction(scale: CGFloat) {
        zoomFactor *= scale
        cameraZoomFactor(zoomFactor)
    }
    
    /// 主鏡頭畫面放大縮小功能 (直接設定比例 - 1x / 2x / 5x)
    /// - Parameter zoomFactor: CGFloat
    func cameraZoomFactor(_ zoomFactor: CGFloat) {
        
        guard let backCamera = cameraDevices.first(where: { $0.position == .back }) else { return }
        
        self.zoomFactor = zoomFactor
        
        let result = backCamera._zoom(with: 0.5, factor: zoomFactor)
                
        switch result {
        case .failure(let error):
            
            if let error = error as? Constant.MyError {
                
                switch error {
                case .isTooLarge: self.zoomFactor = backCamera.maxAvailableVideoZoomFactor
                case .isTooSmall: self.zoomFactor = backCamera.minAvailableVideoZoomFactor
                case .isEmpty, .noTorch, .unknown: break
                }
            }
            
        case .success(let factor): self.zoomFactor = factor ?? backCamera.minAvailableVideoZoomFactor
        }
    }
        
    /// 儲存圖片到相簿 (∵ 前鏡頭的照片會左右相反 ∴ 翻轉再儲存)
    /// - Parameter photos: [AVCapturePhoto]
    func storePicture(with photos: [AVCapturePhoto]) {
        
        parsePhotos(photos)
                
        saveImage(cameraLayerView._screenshot()) { result in
            
            DispatchQueue.main.async { [unowned self] in
                switch result {
                case .failure(let error): presentAlertController(with: "Error", message: error.localizedDescription)
                case .success(_): displayBarButtonItems(true)
                }
            }
        }
    }
    
    /// 將AVCapturePhoto => Image (∵ 前鏡頭的照片會左右相反 ∴ 水平翻轉再儲存)
    /// - Parameter photos: [AVCapturePhoto]
    func parsePhotos(_ photos: [AVCapturePhoto]) {
        
        let firstImage = photos.first?._image()
        let lastImage = photos.last?._image()
        
        mainView.image = (isMainLayerInBack) ? firstImage : firstImage?._flip(with: .leftMirrored)
        subView.image = (!isMainLayerInBack) ? lastImage : lastImage?._flip(with: .leftMirrored)
    }
    
    /// 儲存圖片到使用者相簿
    /// - Parameters:
    ///   - image: UIImage?
    ///   - result: Result<Bool, Error>
    func saveImage(_ image: UIImage?, result: @escaping ((Result<Bool, Error>) -> Void)) {
        
        PHPhotoLibrary.shared()._saveImage(image) { _result in
            switch _result {
            case .failure(let error): result(.failure(error))
            case .success(let isSuccess): result(.success(isSuccess))
            }
        }
    }
    
    /// 設定子畫面的中點位置
    /// - Parameter center: CGPoint?
    func subLayerCenterSetting(_ center: CGPoint?) {
        
        guard let center = center else { return }
        
        subLayerNewCenter = center
        subView.center = center
        cameraLayerView.layer.sublayers?.last?.frame = subView.frame
    }
    
    /// 切換SubView的外型 (圓形 / 正方形 / 長方形)
    /// - Parameter style: Constant.SubLayerStyle
    func exchangeSubViewStyleAction(_ style: Constant.SubLayerStyle) {
        
        switch style {
        case .circle:
            subViewWidthLayoutConstraint.constant = subViewDiameter
            subViewHeightLayoutConstraint.constant = subViewDiameter
            subView.layer.cornerRadius = subViewDiameter * 0.5
            
        case .square(let cornerRadius):
            subViewWidthLayoutConstraint.constant = subViewDiameter + 0.001
            subViewHeightLayoutConstraint.constant = subViewDiameter + 0.001
            subView.layer.cornerRadius = cornerRadius
            
        case .rectangle(let scale, let cornerRadius):
            subViewHeightLayoutConstraint.constant = subViewDiameter * scale
            subView.layer.cornerRadius = cornerRadius
        }
        
        cameraLayerView.layoutIfNeeded()
        cameraLayerView.layer.sublayers?.last?.frame = subView.frame
        cameraLayerView.layer.sublayers?.last?.cornerRadius = subView.layer.cornerRadius
        
        subLayerCenterSetting(subLayerNewCenter)
    }
    
    /// 設定SubLayer的外形選項
    /// - Returns: [Constant.SubLayerStyle]
    func subLayerStyleMaker() -> [Constant.SubLayerStyle] {
        
        let styles: [Constant.SubLayerStyle] = [
            .rectangle(scale: 2.0, cornerRadius: 16.0),
            .square(cornerRadius: 16.0),
            .circle,
        ]
        
        return styles
    }
    
    /// 切換相機閃光燈模式
    /// - Parameter flashMode: AVCaptureDevice.FlashMode
    func switchCameraFlashMode(_ flashMode: AVCaptureDevice.FlashMode) {
        
        currentCameraFlashMode = flashMode
        
        cameraFlashModeButtonItem.image = switch currentCameraFlashMode {
            case .on: UIImage(named: "FlashOn")
            case .off: UIImage(named: "FlashOff")
            default: UIImage(named: "FlashAuto")
        }
    }
    
    /// 切換相機手電筒模式
    /// - Parameter torchMode: AVCaptureDevice.TorchMode
    func switchFlashlightMode(_ torchMode: AVCaptureDevice.TorchMode) {
        
        guard let device = cameraDevices.first else { return }
        
        self.torchMode = torchMode
        
        switch device._torchMode(torchMode) {
        case .failure(_): break
        case .success(let torchMode): self.torchMode = torchMode
        }
        
        flashlightModeButtonItem.image = switch torchMode {
            case .on: UIImage(named: "FlashlightOn")
            default: UIImage(named: "FlashlightOff")
        }
    }
}
