import ArgumentParser
import Foundation

@main
struct Airis: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "airis",
        abstract: "The AI-Native Messenger for Image Operations",
        version: "0.1.0",
        subcommands: []
    )

    func run() throws {
        print("Airis v0.1.0")
        print("Run 'airis --help' for more information.")
    }
}
