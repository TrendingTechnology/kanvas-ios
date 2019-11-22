//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import UIKit

/// Constants for Sticker
private struct Constants {
    static let twoDigitsFormat: String = "%02d"
}

/// A representation for a sticker to be presented in the sticker collection
struct Sticker {
    
    private let baseUrl: String
    private let keyword: String
    private let number: Int
    private let imageExtension: String
    
    var imageUrl: String {
        return "\(baseUrl)\(keyword)/\(String(format: Constants.twoDigitsFormat, number)).\(imageExtension)"
    }
    
    init(baseUrl: String, keyword: String, number: Int, imageExtension: String = "png") {
        self.baseUrl = baseUrl
        self.keyword = keyword
        self.number = number
        self.imageExtension = imageExtension
    }
}