import Foundation

//{
//  "e": "executionReport",        // Event type
//  "E": 1499405658658,            // Event time
//  "s": "ETHBTC",                 // Symbol
//  "c": "mUvoqJxFIILMdfAW5iGSOW", // Client order ID
//  "S": "BUY",                    // Side
//  "o": "LIMIT",                  // Order type
//  "f": "GTC",                    // Time in force
//  "q": "1.00000000",             // Order quantity
//  "p": "0.10264410",             // Order price
//  "P": "0.00000000",             // Stop price
//  "F": "0.00000000",             // Iceberg quantity
//  "g": -1,                       // OrderListId
//  "C": "",                       // Original client order ID; This is the ID of the order being canceled. => "" if it is a new order
//  "x": "NEW",                    // Current execution type
//  "X": "NEW",                    // Current order status
//  "r": "NONE",                   // Order reject reason; will be an error code.
//  "i": 4293153,                  // Order ID
//  "l": "0.00000000",             // Last executed quantity
//  "z": "0.00000000",             // Cumulative filled quantity
//  "L": "0.00000000",             // Last executed price
//  "n": "0",                      // Commission amount
//  "N": null,                     // Commission asset
//  "T": 1499405658657,            // Transaction time
//  "t": -1,                       // Trade ID
//  "I": 8641984,                  // Ignore
//  "w": true,                     // Is the order on the book?
//  "m": false,                    // Is this trade the maker side?
//  "M": false,                    // Ignore
//  "O": 1499405658657,            // Order creation time
//  "Z": "0.00000000",             // Cumulative quote asset transacted quantity
//  "Y": "0.00000000",             // Last quote asset transacted quantity (i.e. lastPrice * lastQty)
//  "Q": "0.00000000"              // Quote Order Qty
//}

struct BinanceUserDataStreamExecutionOrderResponse: Decodable {
    
    let eventTime: Date
    let symbol: String
    let clientOrderId: String
    let side: OrderSide
    let orderType: OrderType
    let orderPrice: Decimal
    let stopPrice: Decimal
    let originalClientOrderId: String
    let currentExecutionType: OrderExecutionType
    let currentOrderStatus: OrderStatus
    let rejectReason: String
    let orderId: Int
    let lastExecutedQuantity: Decimal
    let cumulativeFilledQuantity: Decimal
    let lastExecutedPrice: Decimal
    let commissionAmount: Decimal
    let transactionTime : Date
    let tradeId: Int
    let orderCreationTime: Date
    let cumulativeQuoteAssetTransactedQty: Decimal
    let lastQuoteAssetTransactedQty: Decimal
    let quoteOrderQty: Decimal


    enum CodingKeys: String, CodingKey {
        case orderId = "i"
        case eventTime = "E"
        case symbol = "s"
        case clientOrderId = "c"
        case side = "S"
        case orderType = "o"
        case orderPrice = "p"
        case stopPrice = "P"
        case originalClientOrderId = "C"
        case currentExecutionType = "x"
        case currentOrderStatus = "X"
        case rejectReason = "r"
        case lastExecutedQuantity = "l"
        case cumulativeFilledQuantity = "z"
        case lastExecutedPrice = "L"
        case commissionAmount = "n"
        case tradeId = "t"
        case transactionTime = "T"
        case orderCreationTime = "O"
        case cumulativeQuoteAssetTransactiveQty = "Z"
        case lastQuoteAssetTransactorQty = "Y"
        case quoteOrderQty = "Q"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        orderId = try values.decode(Int.self, forKey: .orderId)
        
        eventTime = Date(timeIntervalSince1970: TimeInterval.fromMilliseconds(try values.decode(Int.self, forKey: .eventTime)))
        
        symbol = try values.decode(String.self, forKey: .symbol)
        clientOrderId = try values.decode(String.self, forKey: .originalClientOrderId)
        side = try BinanceUserDataStreamExecutionOrderResponse.strintToOrderSide(try values.decode(String.self, forKey: .side))
        orderType = try BinanceUserDataStreamExecutionOrderResponse.strintToOrderType(try values.decode(String.self, forKey: .orderType))
        orderPrice = Decimal(try values.decode(String.self, forKey: .orderPrice))!
        stopPrice = Decimal(try values.decode(String.self, forKey: .stopPrice))!
        originalClientOrderId = try values.decode(String.self, forKey: .originalClientOrderId)
        currentExecutionType = try BinanceUserDataStreamExecutionOrderResponse.strintToOrderExecutionType(try values.decode(String.self, forKey: .currentExecutionType))
        currentOrderStatus = try BinanceUserDataStreamExecutionOrderResponse.strintToOrderStatus(try values.decode(String.self, forKey: .currentOrderStatus))
        
        rejectReason = try values.decode(String.self, forKey: .rejectReason)
        lastExecutedQuantity = Decimal(try values.decode(String.self, forKey: .lastExecutedQuantity))!
        cumulativeFilledQuantity = Decimal(try values.decode(String.self, forKey: .cumulativeFilledQuantity))!
        lastExecutedPrice = Decimal(try values.decode(String.self, forKey: .lastExecutedPrice))!
        
        tradeId = try values.decode(Int.self, forKey: .tradeId)
        
        commissionAmount = Decimal(try values.decode(String.self, forKey: .commissionAmount))!
        
        transactionTime = Date(timeIntervalSince1970: TimeInterval.fromMilliseconds(try values.decode(Int.self, forKey: .transactionTime)))
        orderCreationTime = Date(timeIntervalSince1970: TimeInterval.fromMilliseconds(try values.decode(Int.self, forKey: .orderCreationTime)))

        
        cumulativeQuoteAssetTransactedQty = Decimal(try values.decode(String.self, forKey: .cumulativeQuoteAssetTransactiveQty))!
        lastQuoteAssetTransactedQty = Decimal(try values.decode(String.self, forKey: .lastQuoteAssetTransactorQty))!
        quoteOrderQty = Decimal(try values.decode(String.self, forKey: .quoteOrderQty))!
    }
    
    private static func strintToOrderSide(_ value: String) throws -> OrderSide {
        switch value {
        case "BUY":
            return .buy
        case "SELL":
            return .sell
        default:
            throw ExchangePlatformError.parsingError(message: "OrderSide unknown value '\(value)'")
        }
    }
    
    private static func strintToOrderType(_ value: String) throws -> OrderType {
        switch value {
        case "LIMIT":
            return .limit
        case "MARKET":
            return .market
        case "STOP_LOSS":
            return .stopLoss
        case "STOP_LOSS_LIMIT":
            return .stopLossLimit
        case "TAKE_PROFIT":
            return .takeProfitLimit
        case "TAKE_PROFIT_LIMIT":
            return .takeProfitLimit
        case "LIMIT_MAKER":
            return .limitMaker
        default:
            throw ExchangePlatformError.parsingError(message: "OrderType unknown value '\(value)'")
        }
    }
    
    private static func strintToOrderExecutionType(_ value: String) throws -> OrderExecutionType {
        switch value {
        case "NEW":
            return .new
        case "CANCELED":
            return .cancelled
        case "REPLACED":
            return .replaced
        case "REJECTED":
            return .rejected
        case "TRADE":
            return .trade
        case "EXPIRED":
            return .expired
        default:
            throw ExchangePlatformError.parsingError(message: "OrderExecutionType unknown value '\(value)'")
        }
    }
    
    private static func strintToOrderStatus(_ value: String) throws -> OrderStatus {
        switch value {
        case "NEW":
            return .new
        case "PARTIALLY_FILLED":
            return .partiallyFilled
        case "FILLED":
            return .filled
        case "CANCELED":
            return .cancelled
        case "REJECTED":
            return .rejected
        case "EXPIRED":
            return .expired
        default:
            throw ExchangePlatformError.parsingError(message: "OrderStatus unknown value '\(value)'")
        }
    }
}
