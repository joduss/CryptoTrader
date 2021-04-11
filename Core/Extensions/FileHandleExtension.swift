import Foundation

extension FileHandle {
    
    /// Write text in a file.
    func write(_ string: String, encoding: String.Encoding = .utf8) {
        self.write(string.data(using: encoding)!)
    }
}
