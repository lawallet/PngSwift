//
//  PNGChunkTypes.swift
//  PngSwift
//
//  Created by Richard Perry on 9/11/24.
//

import Foundation

public enum PngHeaderTypes: String {
    case IHDR
    case PLTE
    case IDAT
    case IEND
    case cHRM
    case gAMA
    case iCCP
    case sBIT
    case sRGB
    case bKGD
    case hIST
    case tRNS
    case pHYs
    case sPLT
    case tIME
    case iTXt
    case tEXt
    case zTXt
    case unknown
}
