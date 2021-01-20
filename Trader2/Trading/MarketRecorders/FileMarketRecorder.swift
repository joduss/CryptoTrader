import Foundation

/// A MarketRecorder recording to a file.
class FileMarketRecorder: MarketRecorder {
    
    private let api : TradingPlatform
    private let filePath: String
    
    private let fileHandel : FileHandle
    private let semaphore = DispatchSemaphore(value: 1)

    private var priceRecordCache: [TickerRecord] = []
    
    init(api: TradingPlatform, filePath: String) {
        self.api = api
        self.filePath = filePath
        
        if !FileManager.default.fileExists(atPath: filePath) {
            sourcePrint("Creating file at \(filePath)")
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
            self.fileHandel = FileHandle(forUpdatingAtPath: filePath)!
            fileHandel.write("[\n".data(using: .utf8)!)
        }
        else {
            self.fileHandel = FileHandle(forUpdatingAtPath: filePath)!
        }
        
        priceRecordCache.reserveCapacity(1000)
        api.listenBtcUsdPrice()
        self.api.delegate = self
        
        sourcePrint("The price recorder will save prices to \(filePath)")
    }
    
    func priceUpdated(newPrice: Double) {
        
        semaphore.wait()
        
        sourcePrint("New price: \(newPrice)")
        priceRecordCache.append(TickerRecord(time: Date(), price: newPrice))
        
        if priceRecordCache.count > 0 && priceRecordCache.count % 100 == 0 {
            sourcePrint("Saving prices to file...")
            let end = fileHandel.seekToEndOfFile()
            if (end > 20) {
                try! fileHandel.seek(toOffset: end - 1)
            }

            for record in self.priceRecordCache {
                let data = try! JSONEncoder().encode(record)
                fileHandel.write(data)
                fileHandel.write(",\n".data(using: .utf8)!)
            }
            
            self.priceRecordCache.removeAll()
            try! fileHandel.seek(toOffset: fileHandel.seekToEndOfFile() - 2)
            fileHandel.write("\n]".data(using: .utf8)!)
        }
        
        semaphore.signal()
    }
}
