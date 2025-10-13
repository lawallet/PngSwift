//
//  PngPhys.swift
//  PngSwift
//
//  Created by Richard Perry on 10/5/25.
//

import Foundation

public class PngPhys: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    public private(set) var pixelsPerX: UInt32?
    public private(set) var pixelsPerY: UInt32?
    public private(set) var unitSpecifier: UInt8?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        if data.count != 9 { return }
        let xBytes = data[0..<4]
        xBytes.withUnsafeBytes { ptr in
            self.pixelsPerX = ptr.load(as: UInt32.self).bigEndian
        }
        let yBytes = data[4..<8]
        yBytes.withUnsafeBytes { ptr in
            self.pixelsPerY = ptr.load(as: UInt32.self).bigEndian
        }
        self.unitSpecifier = data[8]
        self.dataValid = true
    }
    
}
