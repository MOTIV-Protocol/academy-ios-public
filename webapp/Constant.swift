//
//  Constant.swift
//  webapp
//
//  Created by bohyung kim on 2018. 7. 6..
//  Copyright © 2018년 INSOMENIA. All rights reserved.
//

import UIKit

class Constant: NSObject {
    static let baseURL = "https://"    
}

enum UBEESErrors: Error {
    case DeviceDisconnected, DeviceTooCloset, CannotFoundDevice, AnotherUserDevice, UnknownError
}
