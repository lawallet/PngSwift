//
//  PngChrm.swift
//  PngSwift
//
//  Created by Richard Perry on 10/4/25.
//

import Foundation

public class PngChrm: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    public private(set) var whitePointX: Double?
    public private(set) var whitePointY: Double?
    public private(set) var redX: Double?
    public private(set) var redY: Double?
    public private(set) var greenX: Double?
    public private(set) var greenY: Double?
    public private(set) var blueX: Double?
    public private(set) var blueY: Double?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        if data.count != 32 {
            return
        }
        
        let whitePointXData = data[0..<4]
        whitePointXData.withUnsafeBytes {p in
            let encodedValue: UInt32 = p.load(as: UInt32.self).bigEndian
            self.whitePointX = Double(encodedValue) / 100000.0
        }
        
        let whitePointYData = data[4..<8]
        whitePointYData.withUnsafeBytes {p in
            let encodedValue: UInt32 = p.load(as: UInt32.self).bigEndian
            self.whitePointY = Double(encodedValue) / 100000.0
        }
        let redXData = data[8..<12]
        redXData.withUnsafeBytes {p in
            let encodedValue: UInt32 = p.load(as: UInt32.self).bigEndian
            self.redX = Double(encodedValue) / 100000.0
        }
        let redYData = data[12..<16]
        redYData.withUnsafeBytes {p in
            let encodedValue: UInt32 = p.load(as: UInt32.self).bigEndian
            self.redY = Double(encodedValue) / 100000.0
        }
        let greenXData = data[16..<20]
        greenXData.withUnsafeBytes {p in
            let encodedValue: UInt32 = p.load(as: UInt32.self).bigEndian
            self.greenX = Double(encodedValue) / 100000.0
        }
        let greenYData = data[20..<24]
        greenYData.withUnsafeBytes {p in
            let encodedValue: UInt32 = p.load(as: UInt32.self).bigEndian
            self.greenY = Double(encodedValue) / 100000.0
        }
        let blueXData = data[24..<28]
        blueXData.withUnsafeBytes {p in
            let encodedValue: UInt32 = p.load(as: UInt32.self).bigEndian
            self.blueX = Double(encodedValue) / 100000.0
        }
        let blueYData = data[28..<32]
        blueYData.withUnsafeBytes {p in
            let encodedValue: UInt32 = p.load(as: UInt32.self).bigEndian
            self.blueY = Double(encodedValue) / 100000.0
        }
        self.dataValid = true
    }
}
