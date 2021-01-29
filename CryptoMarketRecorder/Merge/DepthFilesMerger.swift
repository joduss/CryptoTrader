import Foundation
import JoLibrary

class DepthFilesMerger {
    
    private var directoryPath: String
    private var mergedFileHandle: FileHandle
    
    private let jsonDecoder = JSONDecoder()
    
    private var lastId: Int = -1
    
    init(directoryPath: String, mergedFilePath: String) {
        self.directoryPath = directoryPath
        
        if !FileManager.default.fileExists(atPath: mergedFilePath) {
            sourcePrint("Creating file for merge at \(mergedFilePath).")
            FileManager.default.createFile(atPath: mergedFilePath, contents: nil, attributes: nil)
        }
        
        mergedFileHandle = FileHandle(forUpdatingAtPath: mergedFilePath)!
    }
    
    public func merge() {
        
        let files = sortFileByFirstId(files: findFiles())
        
        for filePath in files {
            mergeFile(at: filePath)
        }
    }
    
    /// Searches and returns all depths file in a directory.
    private func findFiles() -> [String] {
        var files: [String] = []
        let enumerator = FileManager.default.enumerator(atPath: directoryPath)

        while let filename = enumerator?.nextObject() as? String {
            FileManager.default.createFile(atPath: directoryPath, contents: nil, attributes: nil)
            
            let filePath = (directoryPath as NSString).appendingPathComponent(filename)
            guard filePath.hasSuffix(".depths") else { continue }
            files.append(filePath)
        }
        
        sourcePrint("Found files to merge: \(files)")
        return files
    }
    
    /// Returns a list of ids
    private func sortFileByFirstId(files: [String]) -> [String]  {
        var idsToFile : [Int : String] = [:]
        
        for file in files {
            let id = firstEntryInFile(file)
            
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
    
    private func firstEntryInFile(_ filePath: String) -> Int {
        let reader = TextFileReader.openFile(at: filePath)
        let id = try! jsonDecoder.decode(MarketDepth.self, from: reader.readLine()!.data(using: .utf8)!).id
        reader.close()
        return id
    }
    
    private func mergeFile(at path: String) {
        let reader = TextFileReader.openFile(at: path)
        
        while let line = reader.readLine() {
            let lineData = line.data(using: .utf8)!
            let marketDepth = try! jsonDecoder.decode(MarketDepth.self, from: lineData)
            if marketDepth.id < lastId {
                sourcePrint("Skipping depth id \(marketDepth.id) because it is already present")
                continue
            }
            
            lastId = marketDepth.id
            mergedFileHandle.write(lineData)
        }
        
        reader.close()
    }
}
