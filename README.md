PngSwift is a Swift implementation of a basic PNG Encoder/Decoder.

## Features.
- Basic and Nonstandard chunks.
- Support for modifiying ancillary chunks data.
- Can either load all chunks or selectively load chunks into memory.
- Save PNG to disk

## Code Example

```swift
let information = try? PngSwift.getPngInformation(location: pngUrl)
// Load all sections
try? information?.populateAllSections()
// Load one section
try? pngInfo?.populate(sectionType: .PLTE)
// Save Png
try? pngInfo?.writePngToDisk(location: saveUrl)
```

## Known Issues/Limitations:
- Modifying critical or non-standard chunks not allowed
- Can not save files with non-standard chunks
