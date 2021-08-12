import Foundation
import JoLibrary

///// Transforms trade data to OHLC.
///// Open - The first traded price
///// High - The highest traded price
///// Low - The lowest traded price
///// Close - The final traded price
///// Volume - The total volume traded by all trades
///// Trades - The number of individual trades
class AggregatedTradeToOHLCDataTransformer {

    private let tradesFile: String

    init(tradesFile: String) {
        self.tradesFile = tradesFile
    }

    func transform(outputFileHandle: FileHandle, aggregationInterval: TimeInterval) throws {

        let reader = TextFileReader.openFile(at: tradesFile)
        let firstTrade = deserialize(line: reader.readLine()!)
        var lineCount = 0

        var previousOhlcRecord: OHLCRecord!
        var currentOhlcRecord: OHLCRecord = OHLCRecord(
            time: intervalOf(trade: firstTrade, lastInterval: Date.init(timeIntervalSinceReferenceDate: 0)),
            trade: firstTrade
        )
        // We go over each record.
        // All data are aggregated in interval, which is aggregated by flooring its time.
        // By aggregating by 60 seconds, 13:01:35, 13:01:45 are aggregated at 13:01:00 but 13:02:01 is 13:02.
        while let line: String = reader.readLine() {
            lineCount += 1

            let trade = deserialize(line: line)
            let lastInterval = currentOhlcRecord.time

            let currentInterval = intervalOf(trade: trade, lastInterval: lastInterval)

            if lineCount % 500000 == 0 && lineCount > 0 {
                print("Lines processed: \(lineCount). Current date: \(trade.time)")
            }

            if currentInterval > lastInterval {
                write(record: currentOhlcRecord, file: outputFileHandle)

                // Prepare next interval
                previousOhlcRecord = currentOhlcRecord

                currentOhlcRecord = OHLCRecord(time: currentInterval, trade: trade)

                // Fill all the interval between last and the new one

                if currentInterval - lastInterval > aggregationInterval {
                    fill(with: previousOhlcRecord,
                         from: previousOhlcRecord.time,
                         to: currentInterval,
                         aggregationInterval: aggregationInterval,
                         to: outputFileHandle
                    )
                }

                continue
            }

            currentOhlcRecord.update(with: trade)
        }

        // Writing last record
        write(record: currentOhlcRecord, file: outputFileHandle)
        
        outputFileHandle.closeFile()
    }

    private func intervalOf(trade: MarketMinimalAggregatedTrade, lastInterval: Date) -> Date {
        let nextInterval = Date(
            timeIntervalSinceReferenceDate:
                floor(trade.time.timeIntervalSinceReferenceDate / 60.0) * 60.0
        )

        guard nextInterval >= lastInterval else {
            fatalError("Current interval is before the previous one.")
        }

        return nextInterval
    }

    private func write(record: OHLCRecord, file: FileHandle) {
        file.write(
            "\(record.time.timeIntervalSince1970),\(record.open),\(record.high),\(record.low),\(record.close),\(record.volume),\(record.trades)\n"
        )
    }

    /// beginFillInterval and toFillInterval are excluded.
    private func fill(
        with previousRecord: OHLCRecord,
        from beginFillInterval: Date,
        to toFillInterval: Date,
        aggregationInterval: TimeInterval,
        to file: FileHandle
    ) {
        var currentInterval = beginFillInterval + aggregationInterval

        while currentInterval < toFillInterval {
            let fillRecord = createEmptyFrom(record: previousRecord, for: currentInterval)
            write(record: fillRecord, file: file)
            currentInterval += aggregationInterval
        }
    }


    /// Deserialize a line ( "price, volume, time")
    private func deserialize(line: String) -> MarketMinimalAggregatedTrade {
        let values = line.substring(start: 0, end: line.count - 1).split(separator: ",")

        return MarketMinimalAggregatedTrade(
            price: Double(String(values[0]))!,
            quantity: Double(String(values[1]))!,
            time: Date(timeIntervalSince1970: TimeInterval(values[2])!)
        )
    }
    
    private func createEmptyFrom(record: OHLCRecord, for interval: Date) -> OHLCRecord {
        return OHLCRecord(open: record.close,
                          high: record.close,
                          low: record.close,
                          close: record.close,
                          volume: 0,
                          trades: 0,
                          time: interval)
    }
}
