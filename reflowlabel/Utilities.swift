import Foundation

extension String {
    func nsRangeFromRange(range : Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16Index(range.startIndex, within: utf16view)
        let to = String.UTF16Index(range.endIndex, within: utf16view)
        let location = utf16view.startIndex.distanceTo(from)
        let length = from.distanceTo(to)
        return NSMakeRange(location, length)
    }
}
