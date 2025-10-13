//
//  Populatable.swift
//  PngSwift
//
//  Created by Richard Perry on 10/7/25.
//

import Foundation

protocol Populatable {
    func populateFields(data: Data)
    var dataValid: Bool { get }
}
