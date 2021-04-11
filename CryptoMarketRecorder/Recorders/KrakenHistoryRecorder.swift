import Foundation

/// https://api.kraken.com/0/public/OHLC
class KrakenHistoryRecorder {
    
    private let url = URL(string: "https://api.kraken.com/0/public/Trades?pair=xbtusd&since=")
    private let outputFile: FileHandle
    private var startDateDisplayed = false
    
    
    init(outputFile: FileHandle) {
        self.outputFile = outputFile
    }
    
    func record(from index: Int) {
        
    }
}

fileprivate class OHLCRecordResponse {
    
}
