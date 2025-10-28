//
//  Item.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 27.09.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
