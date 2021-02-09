import Foundation


enum OrderState {
    case open // The order is open and ready to be closed
    case closed // The order is finished
    case limitLoss // The order is in mode limit loss, meaning we don't have the asset anymore. We sold it to buy it at a lower price.
}
