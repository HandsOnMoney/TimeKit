import Foundation

extension Array {
    public func lowerBound(target: Date, by keyPath: KeyPath<Element, Date>) -> Int {
        if self.isEmpty {
            return -1
        }

        var lo = 0
        var hi = self.count - 1
        var bound = -1
        while lo <= hi {
            let mid = lo + (hi - lo) / 2
            if self[mid][keyPath: keyPath] <= target {
                bound = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return bound
    }

    public func lowerBoundElement(target: Date, by keyPath: KeyPath<Element, Date>) -> Element? {
        guard !isEmpty else { return nil }

        let index = lowerBound(target: target, by: keyPath)

        if index == -1 {
            return nil
        }

        let element = self[index]

        guard element[keyPath: keyPath] <= target else { return nil }

        return element
    }

    /// - Precondition: array must be sorted ascending
    public func mergeReduce<T, TOther>(with other: [TOther], by keyPath: KeyPath<Element, Date>, andBy keyPath2: KeyPath<TOther, Date>, transform: (T?, Element?, TOther?) -> T) -> [T] {
        var res: [T] = []
        var i = 0
        var j = 0

        while i < self.count && j < other.count {
            if self[i][keyPath: keyPath] < other[j][keyPath: keyPath2] {
                res.append(transform(res.last, self[i], nil))
                i += 1
            } else if self[i][keyPath: keyPath] > other[j][keyPath: keyPath2] {
                res.append(transform(res.last, nil, other[j]))
                j += 1
            } else {
                res.append(transform(res.last, self[i], other[j]))
                i += 1
                j += 1
            }
        }

        while i < self.count {
            res.append(transform(res.last, self[i], nil))
            i += 1
        }

        while j < other.count {
            res.append(transform(res.last, nil, other[j]))
            j += 1
        }

        return res
    }
}
