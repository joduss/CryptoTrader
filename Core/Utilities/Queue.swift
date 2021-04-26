import Foundation

public struct Queue<T> {
    
    private var items: [T] = []
    
    public var count: Int { return items.count }
    
    public var limitSize: Int?
            
    public mutating func reserveCapacity(_ capacity: Int) {
        items.reserveCapacity(capacity)
    }
    
    public mutating func enqueue(_ item: T) {
        if let limitSize = self.limitSize, items.count == limitSize {
            items.remove(at: 0)
        }
        
        items.append(item)
    }
    
    public mutating func replaceLast(_ item: T) {
        items[items.count - 1] = item
    }
    
    public mutating func dequeue() -> T {
        return items.remove(at: 0)
    }
    
    public mutating func removeAll() {
        items.removeAll()
    }
    
    public func toArray() -> [T] {
        return items
    }
}
