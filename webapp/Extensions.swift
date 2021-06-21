//
//  Extensions.swift
//  webapp
//
//  Created by bohyung kim on 2018. 7. 10..
//  Copyright © 2018년 INSOMENIA. All rights reserved.
//

import UIKit
extension Array {
    func partition(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}
