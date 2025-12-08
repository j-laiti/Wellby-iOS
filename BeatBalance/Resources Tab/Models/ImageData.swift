//
//  IMageData.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/30/24.
//

import Foundation
import SwiftUI

struct ImageData: Hashable {
    var uiImage: UIImage
    var url: String
    var topic: String = ""
    var path: String = ""
}
