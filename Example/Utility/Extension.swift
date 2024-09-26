//
//  Extension.swift
//  Example
//
//  Created by William.Weng on 2024/8/8.
//

import UIKit
import AVFoundation
import Photos
import MediaPlayer

// MARK: - CGPoint (Operator Overloading)
extension CGPoint {
    
    /// CGPoint的加法
    /// - Parameters:
    ///   - lhs: CGPoint
    ///   - rhs: CGPoint
    /// - Returns: CGPoint
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    /// CGPoint的減法
    /// - Parameters:
    ///   - lhs: CGPoint
    ///   - rhs: CGPoint
    /// - Returns: CGPoint
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

// MARK: - Date (function)
extension Date {
    
    /// 將UTC時間 => 該時區的時間
    /// - 2020-07-07 16:08:50 +0800
    /// - Parameters:
    ///   - dateFormat: 時間格式
    ///   - timeZone: 時區
    /// - Returns: String?
    func _localTime(with dateFormat: Constant.DateFormat = .full, timeZone: TimeZone) -> String? {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "\(dateFormat)"
        dateFormatter.timeZone = timeZone
        
        switch dateFormat {
        case .meridiem(formatLocale: let locale): dateFormatter.locale = locale
        default: break
        }
        
        return dateFormatter.string(from: self)
    }
}

// MARK: - FileManager (function)
extension FileManager {
    
    /// User的「暫存」資料夾
    /// - => ~/tmp/
    /// - Returns: URL
    func _temporaryDirectory() -> URL { return self.temporaryDirectory }
    
    /// [取得User的資料夾](https://cdfq152313.github.io/post/2016-10-11/)
    /// - UIFileSharingEnabled = YES => iOS設置iTunes文件共享
    /// - Parameter directory: User的資料夾名稱
    /// - Returns: [URL]
    func _userDirectory(for directory: FileManager.SearchPathDirectory) -> [URL] { return Self.default.urls(for: directory, in: .userDomainMask) }
    
    /// User的「文件」資料夾URL
    /// - => ~/Documents/ (UIFileSharingEnabled)
    /// - Returns: URL?
    func _documentDirectory() -> URL? { return self._userDirectory(for: .documentDirectory).first }
}

// MARK: - UIApplication (function)
extension UIApplication {
    
    /// [不再自動進入鎖定畫面](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/設定-isidletimerdisabled-讓-iphone-不再自動進入鎖定畫面-89e23f61333b)
    /// - Parameter isAwake: Bool
    func _awake(_ isAwake: Bool) {
        isIdleTimerDisabled = isAwake
    }
}

// MARK: - UIImage (function)
extension UIImage {
    
    /// 圖片翻動 => 鏡射 + 旋轉
    /// - Parameter orientation: 翻動的方向
    /// - Returns: UIImage?
    func _flip(with orientation: UIImage.Orientation = .upMirrored) -> UIImage? {
        
        guard let cgImage = cgImage else { return nil }
        
        let flipImage = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        return flipImage
    }
}

// MARK: - UIView (static function)
extension UIView {
    
    /// 動畫關閉 / 啟動
    /// - Parameters:
    ///   - isEnabled: Bool
    ///   - action: () -> Void
    static func _animations(isEnabled: Bool, action: () -> Void) {
        
        CATransaction.begin()
        UIView.setAnimationsEnabled(isEnabled)
        CATransaction.setDisableActions(!isEnabled)
        
        action()
        
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
    }
}

// MARK: - UIView (function)
extension UIView {
    
    /// [擷取UIView的畫面](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-uigraphicsimagerenderer-將-view-變成圖片-41d00c568903)
    /// - Parameter afterScreenUpdates: 更新後才擷取嗎？
    /// - Returns: UIImage
    func _screenshot(afterScreenUpdates: Bool = true) -> UIImage {
        
        let render = UIGraphicsImageRenderer(size: self.bounds.size)
        let image = render.image { (_) in drawHierarchy(in: self.bounds, afterScreenUpdates: afterScreenUpdates) }
        
        return image
    }
    
    /// [取得ClassType](https://www.gushiciku.cn/pl/peWG/zh-tw)
    /// - Returns: AnyObject
    func _class() -> AnyObject { return type(of: self) }
    
    /// [取得ClassType字串 => 私有類別常用](https://www.jianshu.com/p/062047533def)
    /// - Returns: String
    func _classString() -> String { return String(describing: self._class()) }
}

// MARK: - CALayer (static function)
extension CALayer {
    
    /// Layer動畫開關
    /// - Parameters:
    ///   - isEnabled: Bool
    ///   - action: () -> Void
    static func _animations(isEnabled: Bool, action: () -> Void) {
        
        CATransaction.begin()
        CATransaction.setDisableActions(!isEnabled)
        
        action()
        
        CATransaction.commit()
    }
}

// MARK: - UIViewController (function)
extension UIViewController {
    
    /// 設定UIViewController透明背景 (當Alert用)
    /// - Present Modally
    /// - Parameter backgroundColor: 背景色
    func _transparent(_ backgroundColor: UIColor = .clear) {
        self._modalStyle(backgroundColor, transitionStyle: .crossDissolve, presentationStyle: .overCurrentContext)
    }
    
    /// [設定UIViewController透明背景 (當Alert用)](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-view-controller-實現-ios-app-的彈出視窗-d1c78563bcde)
    /// - Parameters:
    ///   - backgroundColor: 背景色
    ///   - transitionStyle: 轉場的Style
    ///   - presentationStyle: 彈出的Style
    func _modalStyle(_ backgroundColor: UIColor = .white, transitionStyle: UIModalTransitionStyle = .coverVertical, presentationStyle: UIModalPresentationStyle = .currentContext) {
        self.view.backgroundColor = backgroundColor
        self.modalTransitionStyle = transitionStyle
        self.modalPresentationStyle = presentationStyle
    }
}

// MARK: - UIAlertController (static function)
extension UIAlertController {
    
    /// 選擇用的AlertController (OK / Option1 / Option2)
    /// - Parameters:
    ///   - title: 標題文字
    ///   - message: 內容訊息
    ///   - preferredStyle: 彈出的型式
    ///   - actions: 按下OK的動作
    /// - Returns: UIAlertController
    static func _build(with title: String?, message: String?, preferredStyle: UIAlertController.Style = .alert, actions: [Constant.AlertActionInformation]) -> UIAlertController {
        
        let alertController = _baseAlertController(with: title, message: message, preferredStyle: preferredStyle)
        
        actions.forEach { (info) in
            let action = UIAlertAction(title: info.title, style: info.style) { (_) in if let handler = info.handler { handler() } }
            alertController.addAction(action)
        }
        
        return alertController
    }
}

// MARK: - UIAlertController (private static function)
private extension UIAlertController {
    
    /// AlertController基本型 (僅標題文字)
    /// - Parameters:
    ///   - title: 標題文字
    ///   - message: 內容訊息
    ///   - preferredStyle: 彈出的型式
    /// - Returns: UIAlertController
    static func _baseAlertController(with title: String?, message: String?, preferredStyle: UIAlertController.Style = .alert) -> UIAlertController {
        let alertController = Self(title: title, message: message, preferredStyle: preferredStyle)
        return alertController
    }
}

// MARK: - UITapGestureRecognizer (static function)
extension UITapGestureRecognizer {
    
    /// [輕點手勢產生器 (多指)](https://blog.csdn.net/fys_0801/article/details/50605837)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - numberOfTouchesRequired: 需要幾指去點才有反應？
    ///   - numberOfTapsRequired: 需要要點幾下？
    ///   - action: 點下去要做什麼？
    /// - Returns: UITapGestureRecognizer
    static func _build(target: Any?, numberOfTouchesRequired: Int = 1, numberOfTapsRequired: Int = 1, action: Selector?) -> UITapGestureRecognizer {
        
        let recognizer = UITapGestureRecognizer(target: target, action: action)
        
        recognizer.numberOfTapsRequired = numberOfTapsRequired
        recognizer.numberOfTouchesRequired = numberOfTouchesRequired
        
        return recognizer
    }
}

// MARK: - UIPinchGestureRecognizer (static function)
extension UIPinchGestureRecognizer {
    
    /// 縮放手勢產生器 (多指)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - action: 縮放下去要做什麼？
    /// - Returns: UIPanGestureRecognizer
    static func _build(target: Any?, action: Selector?) -> UIPinchGestureRecognizer {
        
        let recognizer = UIPinchGestureRecognizer(target: target, action: action)
        return recognizer
    }
}

// MARK: - UIPanGestureRecognizer (static function)
extension UIPanGestureRecognizer {
    
    /// 拖曳手勢產生器 (單指)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - action: 拖曳下去要做什麼？
    /// - Returns: UIPanGestureRecognizer
    static func _build(target: Any?, action: Selector?) -> UIPanGestureRecognizer {
        
        let recognizer = UIPanGestureRecognizer(target: target, action: action)
        return recognizer
    }
}

// MARK: - UISwipeGestureRecognizer (static function)
extension UISwipeGestureRecognizer {
    
    /// [滑動手勢產生器 (多指)](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/開發-ios-app-的-gesture-手勢功能-uikit-版本-f6cb95075705)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - numberOfTouchesRequired: 需要幾指去滑動才有反應？
    ///   - numberOfTapsRequired: 需要要滑動幾下？
    ///   - action: 滑動下去要做什麼？
    /// - Returns: UISwipeGestureRecognizer
    static func _build(target: Any?, direction: UISwipeGestureRecognizer.Direction, numberOfTouches number: Int = 1, action: Selector?) -> UISwipeGestureRecognizer {
        
        let recognizer = UISwipeGestureRecognizer(target: target, action: action)
        
        recognizer.direction = direction
        recognizer.numberOfTouchesRequired = number

        return recognizer
    }
}

// MARK: - AVCaptureDevice (function)
extension AVCaptureDevice {
    
    /// 判斷鏡頭的位置 (前後) => .front / .back
    func _videoPosition() -> AVCaptureDevice.Position { return self.position }
    
    /// 取得裝置的Input => NSCameraUsageDescription / NSMicrophoneUsageDescription
    func _captureInput() -> Result<AVCaptureDeviceInput, Error> {
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: self)
            return .success(deviceInput)
        } catch {
            return .failure(error)
        }
    }
    
    /// [取得該裝置的硬體參數值](https://developer.apple.com/documentation/avfoundation/avcapturedevice/format)
    /// - Returns: AVCaptureDevice.Format
    func _formatInformation() -> AVCaptureDevice.Format { return activeFormat }
    
    /// [鏡頭縮放](https://developer.apple.com/documentation/avfoundation/avcapturedevice/1624614-ramp)
    /// - Parameters:
    ///   - rate: [比率](https://blog.csdn.net/u012581760/article/details/80936741)
    ///   - factor: [倍率因子](https://stackoverflow.com/questions/45227163/using-avcapturedevice-zoom-settings)
    ///   - isSmooth: [是否要平滑縮放？](https://stackoverflow.com/questions/33180564/pinch-to-zoom-camera)
    /// - Returns: Result<Bool, Error>
    func _zoom(with rate: CGFloat, factor: CGFloat, isSmooth: Bool = false) -> Result<CGFloat?, Error> {
        
        if (factor > maxAvailableVideoZoomFactor) { return .failure(Constant.MyError.isTooLarge) }
        if (factor < minAvailableVideoZoomFactor) { return .failure(Constant.MyError.isTooSmall) }

        let result = self._lockForConfiguration { () -> CGFloat? in
            
            if (isSmooth) {
                self.ramp(toVideoZoomFactor: factor, withRate: Float(rate))
            } else {
                self.videoZoomFactor = factor
            }
            
            return self.videoZoomFactor
        }
        
        return result
    }
    
    /// [停止鏡頭縮放](https://iter01.com/478255.html)
    /// - Returns: Result<Bool, Error>
    func _zoomCancel() -> Result<Bool, Error> {
        
        let result = self._lockForConfiguration { () -> Bool in
            self.cancelVideoZoomRamp()
            return true
        }
        
        return result
    }
    
    /// [設定手電筒模式](https://ithelp.ithome.com.tw/articles/10236699)
    /// - Parameter mode: [AVCaptureDevice.TorchMode](https://developer.apple.com/documentation/avfoundation/avcapturedevice/1386035-torchmode)
    /// - Returns: Result<AVCaptureDevice.TorchMode, Error>
    func _torchMode(_ mode: AVCaptureDevice.TorchMode = .auto) -> Result<AVCaptureDevice.TorchMode, Error> {
        
        if (!hasTorch) { return .failure(Constant.MyError.noTorch) }
        
        let result = self._lockForConfiguration { () -> AVCaptureDevice.TorchMode in
            self.torchMode = mode
            return self.torchMode
        }
        
        return result
    }
}

// MARK: - AVCaptureDevice (function)
private extension AVCaptureDevice {
    
    /// [lock住設備 => 硬體參數設定](https://objccn.io/issue-23-1/)
    /// - Returns: Result<T, Error>
    func _lockForConfiguration<T>(_ block: @escaping (() -> T)) -> Result<T, Error> {
        
        defer { unlockForConfiguration() }
        
        do {
            try lockForConfiguration()
            return .success(block())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - AVCapturePhotoOutput (function)
extension AVCapturePhotoOutput {
    
    /// 擷圖 => 拍照 => photoOutput(_:didFinishProcessingPhoto:error:)
    /// - Parameters:
    ///   - isHighResolutionPhotoEnabled: 高解析度
    ///   - flashMode: 閃光燈 => 自動
    ///   - delegate: AVCapturePhotoCaptureDelegate
    ///   - completion: (() -> Void)?
    func _capturePhoto(isHighResolutionPhotoEnabled: Bool = true, flashMode: AVCaptureDevice.FlashMode, delegate: AVCapturePhotoCaptureDelegate, completion: (() -> Void)? = nil) {
        
        self.isHighResolutionCaptureEnabled = isHighResolutionPhotoEnabled
        
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isHighResolutionPhotoEnabled = isHighResolutionPhotoEnabled
        photoSettings.flashMode = flashMode
        
        capturePhoto(with: photoSettings, delegate: delegate)
        
        completion?()
    }
    
    /// [基本參數設定](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app)
    /// - Parameters:
    ///   - isHighResolutionPhotoEnabled: 高解析度
    ///   - quality: 拍照品質
    func _setting(isHighResolutionPhotoEnabled: Bool = true, quality: AVCapturePhotoOutput.QualityPrioritization) -> Self {
        
        isHighResolutionCaptureEnabled = isHighResolutionPhotoEnabled
        maxPhotoQualityPrioritization = quality
        
        isLivePhotoCaptureEnabled = isLivePhotoCaptureSupported
        isDepthDataDeliveryEnabled = isDepthDataDeliverySupported
        isPortraitEffectsMatteDeliveryEnabled = isPortraitEffectsMatteDeliverySupported
        enabledSemanticSegmentationMatteTypes = availableSemanticSegmentationMatteTypes
        
        return self
    }
}

// MARK: - AVCapturePhoto (function)
extension AVCapturePhoto {
    
    /// AVCapturePhoto => Data
    /// - Returns: Data?
    func _fileData() -> Data? { return fileDataRepresentation() }
    
    /// AVCapturePhoto => UIImage
    /// - Parameter scale: CGFloat
    /// - Returns: UIImage?
    func _image(scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        guard let imageData = self._fileData() else { return nil }
        return UIImage(data: imageData, scale: scale)
    }
}

// MARK: - PHPhotoLibrary (function)
extension PHPhotoLibrary {
    
    /// 儲存圖片到使用者相簿 - PHPhotoLibrary.shared()
    /// - info.plist => NSPhotoLibraryAddUsageDescription / NSPhotoLibraryUsageDescription
    /// - Parameters:
    ///   - image: 要儲存的圖片
    ///   - result: Result<Bool, Error>
    func _saveImage(_ image: UIImage?, result: @escaping (Result<Bool, Error>) -> Void) {
        
        guard let image = image else { result(.failure(Constant.MyError.isEmpty)); return }
        
        performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { (isSuccess, error) in
            if let error = error { result(.failure(error)); return }
            result(.success(isSuccess))
        })
    }
}
