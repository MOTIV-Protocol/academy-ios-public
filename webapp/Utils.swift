//
//  Utils.swift
//  webapp
//
//  Created by bohyung kim on 2018. 7. 6..
//  Copyright © 2018년 INSOMENIA. All rights reserved.
//

import UIKit

class Utils: NSObject {
    static func openSettings() {
        if let settingsUrl = URL(string:UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(settingsUrl)
        }
    }
    
    static func setUserValue(_ key: String, _ value: String?) {
        UserDefaults.standard.set(value, forKey: key)
        
    }
    
    static func getUserValue(_ key: String) -> String? {
        return UserDefaults.standard.value(forKey: key) as? String
    }

}
