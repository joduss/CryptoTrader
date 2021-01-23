import Foundation

/// A MarketRecorder recording to a file.
class FileMarketRecorder: MarketRecorder {
    
    
    private let api : TradingPlatform
    private let savingFrequency: Int
    
    private let tickersFileSemaphore = DispatchSemaphore(value: 1)
    private let tradesFileSemaphore = DispatchSemaphore(value: 1)
    private let depthsFileSemaphore = DispatchSemaphore(value: 1)

    private var tickersFileHandel : FileHandle!
    private var tradesFileHandel : FileHandle!
    private var depthsFileHandel : FileHandle!

    private var tickersCache: [MarketTicker] = []
    private var tradesCache: [MarketAggregatedTrade] = []
    private var depthsCache: [MarketDepth] = []

    private var tickerCount = 0
    private var tradeCount = 0
    private var depthCount = 0
    
    private var lastTrade: Double = 0

    private var aggregatedTicker: MarketTicker?

    init(api: TradingPlatform, savingFrequency: Int = 5000) {
        self.api = api
        self.savingFrequency = savingFrequency
        
        tickersCache.reserveCapacity(savingFrequency)
        tradesCache.reserveCapacity(savingFrequency)
        depthsCache.reserveCapacity(savingFrequency)
        self.api.subscriber = self
    }
    
    func saveTicker(in fileUrl: URL) {
        sourcePrint("The price recorder will save tickers to \(fileUrl.path)")
        tickersFileHandel = createFileHandle(fromUrl: fileUrl)
        self.api.subscribeToTickerStream()
    }
    
    func saveAggregatedTrades(in fileUrl: URL) {
        sourcePrint("The price recorder will save trades to \(fileUrl.path)")
        tradesFileHandel = createFileHandle(fromUrl: fileUrl)
        self.api.subscribeToAggregatedTradeStream()
    }
    
    func saveDepths(in fileUrl: URL) {
        sourcePrint("The price recorder will save depths to \(fileUrl.path)")
        depthsFileHandel = createFileHandle(fromUrl: fileUrl)
        self.api.subscribeToMarketDepthStream()
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

        for record in dataArray {
            let data = try! JSONEncoder().encode(record)
            fileHandle.write(data)
            fileHandle.write("\n".data(using: .utf8)!)
        }
        
        // That's if we want a json array of json objects
        //        try! fileHandle.seek(toOffset: fileHandle.seekToEndOfFile() - 2)
        //        fileHandle.write("\n]".data(using: .utf8)!)
    }
    
    
    // MARK: - TradingPlatformSubscriber
    
    func process(ticker: MarketTicker) {
        
        tickersFileSemaphore.wait()
        
        defer {
            tickersFileSemaphore.signal()
        }
        
        guard let aggregatedTicker = self.aggregatedTicker else {
            self.aggregatedTicker = ticker
            return
        }
        
        if ticker.askPrice == aggregatedTicker.askPrice && ticker.bidPrice == aggregatedTicker.bidPrice {
            self.aggregatedTicker = MarketTicker(date: ticker.date,
                                                 symbol: ticker.symbol,
                                                 bidPrice: ticker.bidPrice,
                                                 bidQuantity: ticker.bidQuantity + aggregatedTicker.bidQuantity,
                                                 askPrice: ticker.askPrice,
                                                 askQuantity: ticker.askQuantity + aggregatedTicker.askQuantity)
            return
        }
        
        tickerCount += 1
        tickersCache.append(aggregatedTicker)
        
        if tickerCount % 10 == 0 {
            sourceReplacablePrint("Ticker \(tickerCount) => Bid: \(aggregatedTicker.bidQuantity) at \(aggregatedTicker.bidPrice) / Ask: \(aggregatedTicker.askQuantity) at \(aggregatedTicker.askPrice)")
        }

        // Use the new ticker which is different from previous.
        self.aggregatedTicker = ticker

                
        if tickersCache.count > 0 && tickersCache.count % savingFrequency == 0 {
            sourcePrint("Saving tickers to file... (Total: \(tickerCount))   ")
            FileMarketRecorder.saveTo(fileHandle: tickersFileHandel, tickersCache)
            tickersCache.removeAll(keepingCapacity: true)
        }
    }
    
    func process(trade: MarketAggregatedTrade) {
        tradesFileSemaphore.wait()
        
        tradeCount += 1
        tradesCache.append(trade)
        
        if tradeCount % 10 == 0 {
            sourceReplacablePrint("Trade \(tradeCount) at price: \(trade.price)")
        }
        
        if tradesCache.count > 0 && tradesCache.count % savingFrequency == 0 {
            sourcePrint("Saving trades to file... (Total: \(tradeCount))    ")
            FileMarketRecorder.saveTo(fileHandle: tradesFileHandel, tradesCache)
            tradesCache.removeAll(keepingCapacity: true)
        }
        
        tradesFileSemaphore.signal()
    }
    
    func process(depthUpdate: MarketDepth) {
        depthsFileSemaphore.wait()
        
        defer {
            depthsFileSemaphore.signal()
        }
        
        depthsCache.append(depthUpdate)
        depthCount += 1
        
        if depthCount % 1 == 0 {
            sourceReplacablePrint("Depth \(depthCount) => There are \(depthUpdate.asks.count) asks and \(depthUpdate.bids.count) bids.")
        }
        
        if depthsCache.count > 0 && depthsCache.count % 150 == 0 {
            sourcePrint("Saving depths to file... (Total: \(depthCount)). There are \(depthUpdate.asks.count) asks and \(depthUpdate.bids.count) bids.    ")
            FileMarketRecorder.saveTo(fileHandle: depthsFileHandel, depthsCache)
            depthsCache.removeAll(keepingCapacity: true)
        }
    }
}
