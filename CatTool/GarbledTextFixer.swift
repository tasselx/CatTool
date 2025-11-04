import Foundation

class GarbledTextFixer {
    private static let gb18030Encoding: String.Encoding = {
        let cfEncoding = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        return String.Encoding(rawValue: nsEncoding)
    }()
    
    private static let keepInSegmentCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ":./_-"))
    private static let chineseScalarRange: ClosedRange<UInt32> = 0x4E00...0x9FFF
    private static let privateUseScalarRange: ClosedRange<UInt32> = 0xE000...0xF8FF
    private static let basicLatinRange: ClosedRange<UInt32> = 0x20...0x7E
    private static let cjkExtensionARange: ClosedRange<UInt32> = 0x3400...0x4DBF
    private static let cjkCompatibilityRange: ClosedRange<UInt32> = 0xF900...0xFAFF
    private static let fullWidthRange: ClosedRange<UInt32> = 0xFF00...0xFFEF
    private static let segmentBoundaryCharacters = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",.;:!?\"'()[]{}<>/\\|@#%^&*+=~`，。！？；：、·「」『』（）【】《》"))
    private static let leadingSegmentCharacters = CharacterSet.alphanumerics
        .union(CharacterSet(charactersIn: "_-"))
    
    static func fix(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        
        var candidates: [String] = [text]
        
        if let latinFixed = convertLatin1ToGB18030(text) {
            candidates.append(latinFixed)
        }
        
        if let fullConverted = convertTreatingAsGB18030(text) {
            candidates.append(fullConverted)
        }
        
        if let segmented = repairSegments(text) {
            candidates.append(segmented)
        }
        
        var seen = Set<String>()
        let uniqueCandidates = candidates.filter { candidate in
            if seen.contains(candidate) {
                return false
            }
            seen.insert(candidate)
            return true
        }
        
        return uniqueCandidates.max(by: { score(for: $0) < score(for: $1) }) ?? text
    }
    
    private static func convertLatin1ToGB18030(_ text: String) -> String? {
        guard let latin1Data = text.data(using: .isoLatin1) else {
            return nil
        }
        guard let decoded = String(data: latin1Data, encoding: gb18030Encoding) else {
            return nil
        }
        return decoded
    }
    
    private static func convertTreatingAsGB18030(_ text: String) -> String? {
        guard let data = text.data(using: gb18030Encoding), !data.isEmpty else {
            return nil
        }
        if let strict = String(data: data, encoding: .utf8) {
            if score(for: strict) >= score(for: text) {
                return strict
            }
            return nil
        }
        let relaxed = String(decoding: data, as: UTF8.self)
        return score(for: relaxed) >= score(for: text) ? relaxed : nil
    }
    
    private static func repairSegments(_ text: String) -> String? {
        var resultCharacters: [Character] = []
        var buffer = ""
        var inSegment = false
        var changed = false
        
        func flushBuffer() {
            guard !buffer.isEmpty else { return }
            if let fixed = decodeMojibakeSegment(buffer), score(for: fixed) >= score(for: buffer) {
                resultCharacters.append(contentsOf: fixed)
                if fixed != buffer {
                    changed = true
                }
            } else {
                resultCharacters.append(contentsOf: buffer)
            }
            buffer.removeAll(keepingCapacity: true)
            inSegment = false
        }
        
        for character in text {
            let isSuspicious = character.unicodeScalars.contains(where: isLikelyMojibakeScalar)
            let isBoundary = character.unicodeScalars.allSatisfy { segmentBoundaryCharacters.contains($0) }
            
            if inSegment {
                if isSuspicious || (!isBoundary && shouldContinueSegment(with: character)) {
                    buffer.append(character)
                } else {
                    flushBuffer()
                    resultCharacters.append(character)
                }
                continue
            }
            
            if isSuspicious {
                if let lastChar = resultCharacters.popLast() {
                    if shouldIncludeLeadingCharacter(lastChar) {
                        buffer.append(lastChar)
                    } else {
                        resultCharacters.append(lastChar)
                    }
                }
                buffer.append(character)
                inSegment = true
            } else {
                resultCharacters.append(character)
            }
        }
        flushBuffer()
        
        guard changed else { return nil }
        return String(resultCharacters)
    }
    
    private static func shouldKeepInSegment(_ scalar: UnicodeScalar) -> Bool {
        if keepInSegmentCharacters.contains(scalar) {
            return true
        }
        return isLikelyMojibakeScalar(scalar)
    }
    
    private static func isLikelyMojibakeScalar(_ scalar: UnicodeScalar) -> Bool {
        if scalar.value == 0xFFFD {
            return true
        }
        if privateUseScalarRange.contains(scalar.value) {
            return true
        }
        if CharacterSet.controlCharacters.contains(scalar) {
            return true
        }
        if isCommonChinese(scalar) || isBasicLatin(scalar) {
            return false
        }
        if CharacterSet.whitespacesAndNewlines.contains(scalar) {
            return false
        }
        if CharacterSet.punctuationCharacters.contains(scalar) {
            return false
        }
        if CharacterSet.symbols.contains(scalar) {
            return false
        }
        if CharacterSet.decimalDigits.contains(scalar) {
            return false
        }
        if let data = String(scalar).data(using: gb18030Encoding), data.count > 1 {
            return true
        }
        return false
    }
    
    private static func score(for text: String) -> Int {
        var score = 0
        for scalar in text.unicodeScalars {
            if chineseScalarRange.contains(scalar.value) {
                score += 5
            } else if cjkExtensionARange.contains(scalar.value) || cjkCompatibilityRange.contains(scalar.value) {
                score += 4
            } else if fullWidthRange.contains(scalar.value) {
                score += 2
            } else if CharacterSet.alphanumerics.contains(scalar) {
                score += 2
            } else if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                score += 1
            } else if CharacterSet.punctuationCharacters.contains(scalar) || keepInSegmentCharacters.contains(scalar) {
                score += 1
            } else if scalar.value == 0xFFFD {
                score -= 12
            } else if CharacterSet.controlCharacters.contains(scalar) {
                score -= 8
            } else if isLikelyMojibakeScalar(scalar) {
                score -= 6
            }
        }
        return score
    }
    
    private static func isCommonChinese(_ scalar: UnicodeScalar) -> Bool {
        if chineseScalarRange.contains(scalar.value) {
            return true
        }
        if cjkExtensionARange.contains(scalar.value) {
            return true
        }
        if cjkCompatibilityRange.contains(scalar.value) {
            return true
        }
        if fullWidthRange.contains(scalar.value) {
            return true
        }
        if (0x3000...0x303F).contains(scalar.value) {
            return true
        }
        return false
    }
    
    private static func isBasicLatin(_ scalar: UnicodeScalar) -> Bool {
        return basicLatinRange.contains(scalar.value)
    }
    
    private static func shouldIncludeLeadingCharacter(_ character: Character) -> Bool {
        if character.unicodeScalars.contains(where: { segmentBoundaryCharacters.contains($0) }) {
            return false
        }
        if character.unicodeScalars.allSatisfy({ leadingSegmentCharacters.contains($0) }) {
            return true
        }
        if character.unicodeScalars.allSatisfy(isCommonChinese) {
            return true
        }
        return false
    }
    
    private static func shouldContinueSegment(with character: Character) -> Bool {
        if character.unicodeScalars.contains(where: { segmentBoundaryCharacters.contains($0) }) {
            return false
        }
        return true
    }
    
    private static func decodeMojibakeSegment(_ segment: String) -> String? {
        guard let data = segment.data(using: gb18030Encoding), !data.isEmpty else {
            return nil
        }
        let decoded = decodeMixedData(data)
        guard !decoded.isEmpty else {
            return nil
        }
        return decoded
    }
    
    private static func decodeMixedData(_ data: Data) -> String {
        var scalars: [UnicodeScalar] = []
        var index = data.startIndex
        
        while index < data.endIndex {
            let byte = data[index]
            
            if byte < 0x80 {
                scalars.append(UnicodeScalar(byte))
                index = data.index(after: index)
                continue
            }
            
            if let length = utf8SequenceLength(for: byte),
               length >= 3,
               data.distance(from: index, to: data.endIndex) >= length {
                let slice = data[index ..< data.index(index, offsetBy: length)]
                if let string = String(bytes: Array(slice), encoding: .utf8) {
                    scalars.append(contentsOf: string.unicodeScalars)
                    index = data.index(index, offsetBy: length)
                    continue
                }
            }
            
            if data.distance(from: index, to: data.endIndex) >= 2 {
                let slice = data[index ..< data.index(index, offsetBy: 2)]
                if let string = String(data: Data(slice), encoding: gb18030Encoding) {
                    scalars.append(contentsOf: string.unicodeScalars)
                    index = data.index(index, offsetBy: 2)
                    continue
                }
            }
            
            index = data.index(after: index)
        }
        
        return String(String.UnicodeScalarView(scalars))
    }
    
    private static func utf8SequenceLength(for byte: UInt8) -> Int? {
        switch byte {
        case 0xC2...0xDF:
            return 2
        case 0xE0...0xEF:
            return 3
        case 0xF0...0xF4:
            return 4
        default:
            return nil
        }
    }
}
