//
//  PngBkgd.swift
//  PngSwift
//
//  Created by Richard Perry on 10/9/25.
//

import Foundation

public class PngBkgd: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    private var bitDepth: UInt8?
    private var colorType: UInt8?
    
    public private(set) var paletteIndex: UInt8?
    public private(set) var transparencyColor: PngRgbValue?
    public private(set) var grayScaleColor: UInt16?
    
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        self.bitDepth = bitDepth
        self.colorType = colorType
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        guard let bitDepth = bitDepth, let colorType = colorType else { return }
        if colorType == 3 {
            if data.count == 1 {
                self.paletteIndex = data[0]
                dataValid = true
            }
            
        } else if colorType == 0 || colorType == 4{
            if data.count == 2 {
                data.withUnsafeBytes { pointer in
                    let grayColor = pointer.load(as: UInt16.self).bigEndian
                    let maxValue = pow(2.0, Double(bitDepth)) - 1.0
                    if Double(grayColor) < maxValue {
                        self.dataValid = true
                        self.grayScaleColor = grayColor
                    }
                    
                }
            }
        } else if colorType == 2 {
            if data.count == 6 {
                let maxValue = pow(2.0, Double(bitDepth)) - 1.0
                var red: UInt16 = 0
                let redData: Data = data[0..<2]
                redData.withUnsafeBytes { pointer in
                    red = pointer.load(as: UInt16.self).bigEndian
                }
                if Double(red) > maxValue {
                    return
                }
                var green: UInt16 = 0
                let greenData: Data = data[2..<4]
                greenData.withUnsafeBytes { pointer in
                    green = pointer.load(as: UInt16.self).bigEndian
                }
                if Double(green) > maxValue {
                    return
                }
                var blue: UInt16 = 0
                let blueData: Data = data[4..<6]
                blueData.withUnsafeBytes { pointer in
                    blue = pointer.load(as: UInt16.self).bigEndian
                }
                if Double(blue) > maxValue {
                    return
                }
                self.transparencyColor = PngRgbValue(red: red, green: green, blue: blue)
                self.dataValid = true
            }
            
        }
    }
}
