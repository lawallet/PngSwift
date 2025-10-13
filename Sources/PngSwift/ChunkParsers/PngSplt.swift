//
//  PngSplt.swift
//  PngSwift
//
//  Created by Richard Perry on 10/10/25.
//

import Foundation

public struct PngReducedPaltteEntry {
    public private(set) var red: UInt16
    public private(set) var green: UInt16
    public private(set) var blue: UInt16
    public private(set) var alpha: UInt16
    public private(set) var frequency: UInt16
}

public class PngSplt: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    var paletteName: String?
    var reducedPalette: [PngReducedPaltteEntry]?
    var sampleDepth: UInt8?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        var dataPos = 0
        var nameArray: [UInt8] = []
        for byte in data {
            // Is character in latin set
            if byte == 0 {
                break
            }
            if (byte >= 33 && byte <= 126) || (byte >= 161 && byte <= 255) || byte == 32 {
                if dataPos == 79 {
                    return
                }
                
                if dataPos == 0 && byte == 32 {
                    // No leading spaces allowed
                    return
                } else {
                    nameArray.append(byte)
                }
                dataPos += 1
            }
        }
        if nameArray.count == 0 {
            return
        }
        guard let paletteName = String(bytes: nameArray, encoding: .isoLatin1) else { return }
        self.paletteName = paletteName
        // Move to position after null terminator
        dataPos += 1
        if dataPos >= data.count { return }
        self.sampleDepth = data[dataPos]
        let divisibleLength: Int
        if sampleDepth == 8 {
            divisibleLength = 6
        } else if sampleDepth == 16 {
            divisibleLength = 10
        } else {
            return
        }
        // Move data pointer to palette data
        dataPos += 1
        let paletteData: Data = data[dataPos...]
        if paletteData.count % divisibleLength != 0 { return }
        self.reducedPalette = []
        if sampleDepth == 8 {
            for i in stride(from: 0, to: paletteData.count, by: 6) {
                let red: UInt8 = paletteData[i]
                let green: UInt8 = paletteData[i + 1]
                let blue: UInt8 = paletteData[i + 2]
                let alpha: UInt8 = paletteData[i + 3]
                let freqData = paletteData[i + 4..<i + 6]
                var frequency: UInt16 = 0
                         
                freqData.withUnsafeBytes {p in
                    frequency = p.load(as: UInt16.self)
                }
                let palette = PngReducedPaltteEntry(red: UInt16(red), green: UInt16(green), blue: UInt16(blue), alpha: UInt16(alpha), frequency: frequency)
                self.reducedPalette?.append(palette)
            }
            self.dataValid = true
        } else {
            for i in stride(from: 0, to: paletteData.count, by: 10) {
                let redData = data[i..<i+2]
                var red: UInt16 = 0
                redData.withUnsafeBytes {p in
                    red = p.load(as: UInt16.self)
                }
                let greenData = data[i+2..<i+4]
                var green: UInt16 = 0
                greenData.withUnsafeBytes {p in
                    green = p.load(as: UInt16.self)
                }
                let blueData = data[i+4..<i+6]
                var blue: UInt16 = 0
                blueData.withUnsafeBytes {p in
                    blue = p.load(as: UInt16.self)
                }
                let alphaData = data[i+6..<i+8]
                var alpha: UInt16 = 0
                alphaData.withUnsafeBytes {p in
                    alpha = p.load(as: UInt16.self)
                }
                let freqData = data[i+8..<i+10]
                var frequency: UInt16 = 0
                freqData.withUnsafeBytes {p in
                    frequency = p.load(as: UInt16.self)
                }
                let palette = PngReducedPaltteEntry(red: red, green: green, blue: blue, alpha: alpha, frequency: frequency)
                self.reducedPalette?.append(palette)
            }
            self.dataValid = true
        }
    }
}
