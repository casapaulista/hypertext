// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser

@main
struct Hypertext: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hx",
        abstract: "An elegant static site generator",
        subcommands: [Init.self, Build.self, Serve.self]
    )
}

extension Hypertext {
    struct Init: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Create a new Hypertext project")
        @Argument(help: "Name of the project")
        var name: String

        mutating func run() throws {
            print("Hello, world!")
        }
    }
    struct Build: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Deletes the output directory if there is one and builds the site")
        mutating func run() throws {
            print("Hello, world!")
        }
    }
    struct Serve: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Serve the site. Rebuild and reload on change automatically")
        mutating func run() throws {
            print("Hello, world!")
        }
    }
}
