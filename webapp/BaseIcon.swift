

import Foundation
import UIKit
import CoreText
import Dispatch

open class BaseIcon {
    
    open static let instance = BaseIcon()
    
    fileprivate var customFontLoaded = false
    fileprivate let load_queue = DispatchQueue(label: "com.insomenia.font.load.queue", attributes: [])
    
    fileprivate var fontsMap :[String: IconFont] = [:]
    
    fileprivate init() {
        
    }
    
    open func addCustomFont(_ prefix: String, fontFileName: String, fontName: String, fontIconMap: [String: String]) {
        fontsMap[prefix] = CustomIconFont(fontFileName: fontFileName, fontName: fontName, fontMap: fontIconMap)
    }
    
    open func loadAllAsync() {
        self.load_queue.async(execute: {
            self.loadAllSync()
        })
    }
    
    open func loadAllSync() {
        for font in fontsMap.values {
            font.loadFontIfNecessary()
        }
    }
    
    open func getNSMutableAttributedString(_ iconName: String, fontSize: CGFloat) -> NSMutableAttributedString? {
        for fontPrefix in fontsMap.keys {
            if iconName.hasPrefix(fontPrefix) {
                let iconFont = fontsMap[fontPrefix]!
                if let iconValue = iconFont.getIconValue(iconName) {
                    let iconUnicodeValue = iconValue.substring(to: iconValue.index(iconValue.startIndex, offsetBy: 1))
                    if let uiFont = iconFont.getUIFont(fontSize) {
                        let attrs = [NSAttributedStringKey.font : uiFont, NSAttributedStringKey.foregroundColor : UIColor.white]
                        return NSMutableAttributedString(string:iconUnicodeValue, attributes:attrs)
                    }
                }
            }
        }
        return nil
    }
    
    open func getUIImage(_ iconName: String, iconSize: CGFloat, iconColour: UIColor = UIColor.black, imageSize: CGSize) -> UIImage {
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.left
        style.baseWritingDirection = NSWritingDirection.leftToRight
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0);
        let attString = getNSMutableAttributedString(iconName, fontSize: iconSize)
        if attString != nil {
            attString?.addAttributes([NSAttributedStringKey.foregroundColor: iconColour, NSAttributedStringKey.paragraphStyle: style], range: NSMakeRange(0, attString!.length))
            // get the target bounding rect in order to center the icon within the UIImage:
            let ctx = NSStringDrawingContext()
            let boundingRect = attString!.boundingRect(with: CGSize(width: iconSize, height: iconSize), options: NSStringDrawingOptions.usesDeviceMetrics, context: ctx)
            
            attString!.draw(in: CGRect(x: (imageSize.width/2.0) - boundingRect.size.width/2.0, y: (imageSize.height/2.0) - boundingRect.size.height/2.0, width: imageSize.width, height: imageSize.height))
            
            var iconImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
//            if(iconImage!.responds(to: #selector(UIImage.withRenderingMode(_:)(_:)))){
//                iconImage = iconImage!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
//            }
            
            return iconImage!
        } else {
            return UIImage()
        }
    }
    
}

private class CustomIconFont: IconFont {
    
    fileprivate let fontFileName: String
    fileprivate let fontName: String
    fileprivate let fontMap: [String: String]
    fileprivate var fontLoadedAttempted = false
    fileprivate var fontLoadedSucceed = false
    
    init(fontFileName: String, fontName: String, fontMap: [String: String]) {
        self.fontFileName = fontFileName
        self.fontName = fontName
        self.fontMap = fontMap
    }
    
    func loadFontIfNecessary() {
        if (!self.fontLoadedAttempted) {
            self.fontLoadedAttempted = true
            self.fontLoadedSucceed = loadFontFromFile(self.fontFileName, forClass: BaseIcon.self, isCustom: true)
        }
    }
    
    func getUIFont(_ fontSize: CGFloat) -> UIFont? {
        self.loadFontIfNecessary()
        if (self.fontLoadedSucceed) {
            return UIFont(name: self.fontName, size: fontSize)
        } else {
            return nil
        }
    }
    
    func getIconValue(_ iconName: String) -> String? {
        return self.fontMap[iconName]
    }
    
}

private func loadFontFromFile(_ fontFileName: String, forClass: AnyClass, isCustom: Bool) -> Bool{
    let bundle = Bundle(for: forClass)
    var fontURL: URL?
    _ = bundle.bundleIdentifier
    
    fontURL = bundle.url(forResource: fontFileName, withExtension: "ttf")
    
    if fontURL != nil {
        let data = try! Data(contentsOf: fontURL!)
        let provider = CGDataProvider(data: data as CFData)
        let font = CGFont(provider!)
        
        if (!CTFontManagerRegisterGraphicsFont(font!, nil)) {
            NSLog("Failed to load font \(fontFileName)");
            return false
        } else {
            return true
        }
    } else {
        NSLog("Failed to load font \(fontFileName) because the file \(fontFileName) is not available");
        return false
    }
}

private protocol IconFont {
    func loadFontIfNecessary()
    func getUIFont(_ fontSize: CGFloat) -> UIFont?
    func getIconValue(_ iconName: String) -> String?
}
