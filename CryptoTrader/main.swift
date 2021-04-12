import Foundation
import ArgumentParser

let arguments = CommandLine.arguments


struct TraderMain: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        subcommands: [
            Trade.self,
            Simulate.self,
            GridSearch.self
        ]
    )
}


TraderMain.main()
RunLoop.main.run()
