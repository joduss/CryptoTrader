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

                let newInterval = intervalOf(trade: trade, lastInterval: Date(timeIntervalSinceReferenceDate: 0))
                currentOhlcRecord = OHLCRecord(time: newInterval, trade: trade)

                // Fill all the interval between last and the new one

                if newInterval - currentInterval > aggregationInterval {
                    fill(with: previousOhlcRecord,
                         from: previousOhlcRecord.time,
                         to: newInterval,
                         aggregationInterval: aggregationInterval,
                         to: outputFileHandle
                    )
                }

                continue
            }

            currentOhlcRecord.update(with: trade)
        }

        outputFileHandle.closeFile()
    }

    private func intervalOf(trade: BasicTrade, lastInterval: Date) -> Date {
        let nextInterval = Date(
            timeIntervalSinceReferenceDate:
                floor(trade.time.timeIntervalSinceReferenceDate / 60) * 60
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
            let fillRecord = OHLCRecord(time: currentInterval, ohlc: previousRecord)
            write(record: fillRecord, file: file)
            currentInterval += aggregationInterval
        }
    }


    /// Deserialize a line ( "price, volume, time")
    private func deserialize(line: String) -> BasicTrade {
        let values = line.substring(start: 0, end: line.count - 1).split(separator: ",")

        return BasicTrade(
            price: Double(values[0])!,
            quantity: Double(values[1])!,
            time: Date(timeIntervalSince1970: TimeInterval(values[2])!)
        )
    }
}
