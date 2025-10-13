//
//  PngSbit.swift
//  PngSwift
//
//  Created by Richard Perry on 10/11/25.
//

import Foundation

public class PngSbit: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    private var colorType: UInt8?
    
    public private(set) var red: UInt8?
    public private(set) var green: UInt8?
    public private(set) var blue: UInt8?
    public private(set) var alpha: UInt8?
    public private(set) var significantBits: UInt8?
    public private(set) var grayscale: UInt8?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        self.colorType = colorType
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        guard let colorType = colorType else { return }
        
        switch colorType {
        case 0:
            if data.count != 1 { return }
            self.significantBits = data[0]
            self.dataValid = true
        case 2:
            if data.count != 3 { return }
            self.red = data[0]
            self.green = data[1]
            self.blue = data[2]
            self.dataValid = true
        case 3:
            if data.count != 3 { return }
            self.red = data[0]
            self.green = data[1]
            self.blue = data[2]
            dataValid = true
        case 4:
            if data.count != 2 { return }
            self.grayscale = data[0]
            self.alpha = data[1]
            self.dataValid = true
        case 6:
            if data.count != 4 { return }
            self.red = data[0]
            self.green = data[1]
            self.blue = data[2]
            self.alpha = data[3]
            self.dataValid = true
        default:
            return
        }
    }
}
