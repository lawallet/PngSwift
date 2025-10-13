//
//  PngSrgb.swift
//  PngSwift
//
//  Created by Richard Perry on 10/4/25.
//

import Foundation

public enum SrgbIntent: UInt8 {
    case perceptual = 0
    case relativeColorimetric
    case saturation
    case absoluteColorimetric
    case invalid
}

public class PngSrgb: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    public private(set) var intent: SrgbIntent?
    var rawIntent: uint8?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        if data.count != 1 { return }
        data.withUnsafeBytes { ptr in
            self.rawIntent = ptr.load(as: UInt8.self)
        }
        if self.rawIntent ?? 99 > 3 { return }
        self.intent = SrgbIntent(rawValue: rawIntent!) ?? .invalid
        self.dataValid = true
    }
}
