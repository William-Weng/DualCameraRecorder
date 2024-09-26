//
//  Constant.swift
//  Example
//
//  Created by William.Weng on 2024/8/8.
//

import UIKit
import AVFoundation

// MARK: - Constant
final class Constant: NSObject {}

// MARK: - typealias
extension Constant {
    
    typealias AlertActionInformation = (title: String?, style: UIAlertAction.Style, handler: (() -> Void)?)     // UIAlertController的按鍵相關資訊
    typealias VedioSize = (width: Int, height: Int)                                                             // 影片的尺寸 (寬 / 高)
}

// MARK: - enum
extension Constant {
    
    /// 自訂錯誤
    enum MyError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }
        
        case unknown
        case isTooLarge
        case isTooSmall
        case isEmpty
        case noTorch
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {
            
            switch self {
            case .unknown: return "未知錯誤"
            case .isTooLarge: return "數值過大"
            case .isTooSmall: return "數值過小"
            case .isEmpty: return "資料是空的"
            case .noTorch: return "該裝置沒有手電筒"
            }
        }
    }
    
    /// 小鏡頭Layer的外形
    enum SubLayerStyle {
        
        case circle                                                         // 圓形
        case square(cornerRadius: CGFloat = 8.0)                            // 正方形
        case rectangle(scale: CGFloat = 0.5, cornerRadius: CGFloat = 8.0)   // 長方形
        
        /// 示意圖
        /// - Returns: UIImage?
        func icon() -> UIImage? {
            
            let imageName = switch self {
            case .circle: "Circle"
            case .square(_): "Square"
            case .rectangle(_, _): "Rectangle"
            }
            
            return UIImage(named: imageName)
        }
    }
    
    /// 私有類別的名稱
    enum PrivateClass: String {
        case MPVolumeSlider = "MPVolumeSlider"  // 系統音量進度條的UISlider
    }
    
    /// [時間的格式](https://nsdateformatter.com)
    enum DateFormat: CustomStringConvertible {
        
        var description: String { return toString() }
        
        case full
        case long
        case middle
        case meridiem(formatLocale: Locale)
        case short
        case timeZone
        case time
        case yearMonth
        case monthDay
        case day
        case web
        case custom(format: String)
        
        /// [轉成對應的字串](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/dateformatter-的-am-pm-問題-5e0d301e8998)
        private func toString() -> String {
            
            switch self {
            case .full: return "yyyy-MM-dd HH:mm:ss ZZZ"
            case .long: return "yyyy-MM-dd HH:mm:ss"
            case .middle: return "yyyy-MM-dd HH:mm"
            case .meridiem: return "yyyy-MM-dd hh:mm a"
            case .short: return "yyyy-MM-dd"
            case .timeZone: return "ZZZ"
            case .time: return "HH:mm:ss"
            case .yearMonth: return "yyyy-MM"
            case .monthDay: return "MM-dd"
            case .day: return "dd"
            case .web: return "E, dd MM yyyy hh:mm:ss ZZZ"
            case .custom(let format): return format
            }
        }
    }
}
