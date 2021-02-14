import Foundation
import JoLibrary

/// A MarketRecorder recording to a file.
final class MarketFileRecorder: MarketRecorder {
    
    private let marketStream : ExchangeMarketDataStream
    private let savingFrequency: Int
    
    private let printFrequency = 20
    
    private let tradesQueue = DispatchQueue(label: "Trade")
    private let tickersQueue = DispatchQueue(label: "Tickers")
    private let depthsQueue = DispatchQueue(label: "Depths")

    private let tickersSemaphore = DispatchSemaphore(value: 1)
    private let tradeFileSemaphore = DispatchSemaphore(value: 1)
    private let depthsSemaphore = DispatchSemaphore(value: 1)
    private let depthsBackupFileSemaphore = DispatchSemaphore(value: 1)

    private var tickersFileHandel : FileHandle!
    private var tradesFileHandel : FileHandle!
    private var depthsFileHandel : FileHandle!
    private var depthsBackupFileHandel : FileHandle!


    private var tickersCache: [MarketTicker] = []
    private var tradesCache: [MarketAggregatedTrade] = []
    private var depthsCache: [MarketDepth] = []

    private var tickerCount = 0
    private var tradeCount = 0
    private var depthCount = 0
    
    private var lastTrade: Double = 0
    private var lastTicker: MarketTicker?

    init(api: ExchangeMarketDataStream, savingFrequency: Int = 5000) {
        self.marketStream = api
        self.savingFrequency = savingFrequency
     
        tickersCache.reserveCapacity(savingFrequency)
        tradesCache.reserveCapacity(savingFrequency)
        depthsCache.reserveCapacity(savingFrequency)
        
        self.marketStream.subscriber = self
    }
    
    // MARK: Configuration of the recorder
    
    func saveTicker(in fileUrl: URL) {
        sourcePrint("The price recorder will save tickers to \(fileUrl.path)")
        tickersFileHandel = createFileHandle(fromUrl: fileUrl)
        self.marketStream.subscribeToTickerStream()
    }
    
    func saveAggregatedTrades(in fileUrl: URL) {
        sourcePrint("The price recorder will save trades to \(fileUrl.path)")
        tradesFileHandel = createFileHandle(fromUrl: fileUrl)
        self.marketStream.subscribeToAggregatedTradeStream()
    }
    
    func saveDepths(in fileUrl: URL) {
        sourcePrint("The price recorder will save depths to \(fileUrl.path)")
        depthsFileHandel = createFileHandle(fromUrl: fileUrl)
        self.marketStream.subscribeToMarketDepthStream()
    }
    
    func saveDepthBackup(in fileUrl: URL) {
        sourcePrint("The price recorder will save the depths backup to \(fileUrl.path)")
        depthsBackupFileHandel = createFileHandle(fromUrl: fileUrl)
    }
    
    // MARK: Helpers
    
    private func createFileHandle(fromUrl url: URL) -> FileHandle {
        let path = url.path
        
        if !FileManager.default.fileExists(atPath: path) {
            sourcePrint("Creating file at \(path)")
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            let fileHandel = FileHandle(forUpdatingAtPath: path)!
            // That's if we want a json array of json objects
            //            fileHandel.write("[\n".data(using: .utf8)!)
            
            return fileHandel
        }
        else {
            return FileHandle(forUpdatingAtPath: path)!
        }
    }
    
    private static func saveTo<T>(fileHandle: FileHandle, _ dataArray: [T]) where T:Encodable {
//        let end = fileHandle.seekToEndOfFile()
        // That's if we want a json array of json objects
        //        if (end > 20) {
        //            try! fileHandle.seek(toOffset: end - 1)
        //        }

        let encoder = JSONEncoder()
        
        for record in dataArray {
            let data = try! encoder.encode(record)
            fileHandle.write(data)
            fileHandle.write("\n".data(using: .utf8)!)
        }
        
        // That's if we want a json array of json objects
        //        try! fileHandle.seek(toOffset: fileHandle.seekToEndOfFile() - 2)
        //        fileHandle.write("\n]".data(using: .utf8)!)
    }
    
    
    // MARK: - TradingPlatformSubscriber
    
    // MARK: Tickers
    func process(ticker: MarketTicker) {
        tickersQueue.async {
            self.tickersSemaphore.wait()
            self.processThreadSafe(ticker: ticker)
            self.tickersSemaphore.signal()
        }
    }
    
    func processThreadSafe(ticker: MarketTicker) {
        guard let lastTicker = self.lastTicker else {
            self.lastTicker = ticker
            return
        }

        // If the bid and ask price are the same, we just update it.
        if ticker.askPrice == lastTicker.askPrice && ticker.bidPrice == lastTicker.bidPrice {
            self.lastTicker = ticker
            return
        }

        tickerCount += 1
        tickersCache.append(lastTicker)

        if tickerCount % printFrequency == 0 {
            sourceReplacablePrint("Ticker \(tickerCount) => Bid: \(lastTicker.bidQuantity) at \(lastTicker.bidPrice) / Ask: \(lastTicker.askQuantity) at \(lastTicker.askPrice)")
        }

        // Use the new ticker which is different from previous.
        self.lastTicker = ticker
        
        if tickersCache.count > 0 && tickersCache.count % savingFrequency == 0 {
            sourcePrint("Saving tickers to file... (Total: \(tickerCount))   ")
            MarketFileRecorder.saveTo(fileHandle: self.tickersFileHandel, self.tickersCache)
            self.tickersCache.removeAll(keepingCapacity: true)
        }
    }
    
    // MARK: Trades
    
    func process(trade: MarketAggregatedTrade) {
        tradesQueue.async {
            self.tradeFileSemaphore.wait()
            self.processThreadSafe(trade: trade)
            self.tradeFileSemaphore.signal()
        }
    }
    
    func processThreadSafe(trade: MarketAggregatedTrade) {
        tradeCount += 1
        tradesCache.append(trade)

        if tradeCount % printFrequency == 0 {
            sourceReplacablePrint("Trade \(tradeCount) at price: \(trade.price)")
        }
        
        if tradesCache.count > 0 && tradesCache.count % savingFrequency == 0 {
            sourcePrint("Saving trades to file... (Total: \(tradeCount))    ")
            MarketFileRecorder.saveTo(fileHandle: self.tradesFileHandel, self.tradesCache)
            tradesCache.removeAll(keepingCapacity: true)
        }
    }
    
    
    // MARK: Depths

    func process(depthUpdate: MarketDepth) {
        depthsQueue.async {
            self.depthsSemaphore.wait()
            self.threadSafeProcess(depthUpdate: depthUpdate)
            self.depthsSemaphore.signal()
        }
    }
    
    private func threadSafeProcess(depthUpdate: MarketDepth) {
        depthsCache.append(depthUpdate)
        depthCount += 1
        
        // This method is called every second
        sourceReplacablePrint("Depth \(depthCount) => There are \(depthUpdate.asks.count) asks and \(depthUpdate.bids.count) bids.")
        
        if depthsCache.count > 0 && depthsCache.count % (savingFrequency / 30) == 0 {
            sourcePrint("Saving depths to file... (Total: \(depthCount)). There are \(depthUpdate.asks.count) asks and \(depthUpdate.bids.count) bids (not aggregated).    ")
            
            MarketFileRecorder.saveTo(fileHandle: self.depthsFileHandel, self.depthsCache)
            
            // Saving the backup which can be used to continue the process with current depths.
            // (Only approximate, which should be enough)
            try! self.depthsBackupFileHandel.seek(toOffset: 0)
            try! self.depthsBackupFileHandel.truncate(atOffset: 0)
            self.depthsBackupFileHandel.write(try! JSONEncoder().encode(self.depthsCache.last!.backup()))
            
            self.depthsCache.removeAll(keepingCapacity: true)
        }
    }
}
