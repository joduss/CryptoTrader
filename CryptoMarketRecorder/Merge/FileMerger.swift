import Foundation
import JoLibrary

public class FileMerger {
    
    private var directoryPath: String
    private var mergedFileHandle: FileHandle
    private let fileExtension: String
    
    private var lastId: Int = -1
    
    /// This value is used when printing the objects that are skipped such as (objectTypeName with id is skipped)
    open var objectTypeName: String = ""
    
    public init(directoryPath: String, mergedFilePath: String) {
        self.directoryPath = directoryPath
        
        if !FileManager.default.fileExists(atPath: mergedFilePath) {
            sourcePrint("Creating file for merge at \(mergedFilePath).")
            FileManager.default.createFile(atPath: mergedFilePath, contents: nil, attributes: nil)
        }
        
        mergedFileHandle = FileHandle(forUpdatingAtPath: mergedFilePath)!
        fileExtension = (mergedFilePath as NSString).pathExtension
    }
    
    // MARK: Public methods
    
    /// Merge of the files from the directory.
    public func merge() throws {
        let files = try sortFileByFirstId(files: findFiles())
        
        for filePath in files {
            try mergeFile(at: filePath)
        }
    }
    
    /// Returns the id of the object serialized in the specified line.
    public func objectId(inLine: String) throws -> Int {
        preconditionFailure("This method must be overridden")
    }
    
    
    // MARK: - Merge logic
    
    /// Searches and returns all depths file in a directory.
    private func findFiles() -> [String] {
        var files: [String] = []
        let enumerator = FileManager.default.enumerator(atPath: directoryPath)

        while let filename = enumerator?.nextObject() as? String {
            FileManager.default.createFile(atPath: directoryPath, contents: nil, attributes: nil)
            
            let filePath = (directoryPath as NSString).appendingPathComponent(filename)
            guard filePath.hasSuffix(".\(fileExtension)") else { continue }
            files.append(filePath)
        }
        
        sourcePrint("Found files to merge: \(files)")
        return files
    }
    
    /// Returns a list of ids, sorted from smaller to largest
    private func sortFileByFirstId(files: [String]) throws -> [String]  {
        var idsToFile : [Int : String] = [:]
        
        for file in files {
            let id = try firstEntryInFile(file)
            
            if idsToFile.keys.contains(id) {
                sourcePrint("ERROR: two files start with the same market depth id!")
                exit(1)
            }
            
            idsToFile[id] = file
        }
        
        var sortedFiles: [String] = []
        
        for id in idsToFile.keys.sorted() {
            sortedFiles.append(idsToFile[id]!)
        }
        
        return sortedFiles
    }
    
    /// Returns the id of the first object in the file.
    private func firstEntryInFile(_ filePath: String) throws -> Int {
        let reader = TextFileReader.openFile(at: filePath)
        let id = try objectId(inLine: reader.readLine()!)
        reader.close()
        return id
    }
    
    /// Merge a specific file.
    private func mergeFile(at path: String) throws {
        let reader = TextFileReader.openFile(at: path)
        
        var lineCount = 0
        
        while let line: String = reader.readLine() {
            var lineId: Int = -1
            var lineData: Data!
            // The deserialization has a memory leak during deserialization.
            try autoreleasepool {
                lineData = line.data(using: .utf8)!
                lineId = try objectId(inLine: line)
            }
            
            if lineId <= lastId {
                sourcePrint("\(self) is skipping id \(lineId) because it is already present")
                continue
            }
            
            lastId = lineId
            mergedFileHandle.write(lineData)
            
            lineCount += 1
            
            if lineCount % 350000 == 0 {
                try! mergedFileHandle.synchronize()
            }
            
        }
        
        mergedFileHandle.synchronizeFile()
        
        reader.close()
    }
}
