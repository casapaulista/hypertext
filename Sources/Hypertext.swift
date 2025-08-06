// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Blueprint
import Foundation
import Swifter
import Syntax

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}

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
        func run() throws {
            let fileManager = FileManager.default

            // Setting path for directories
            let contentDirectory = URL(fileURLWithPath: "content", isDirectory: true)
            let staticDirectory = URL(fileURLWithPath: "static", isDirectory: true)
            let stylesDirectory = URL(fileURLWithPath: "styles", isDirectory: true)
            let templatesDirectory = URL(fileURLWithPath: "templates", isDirectory: true)

            // Creating directories
            try fileManager.createDirectory(at: contentDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: staticDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: stylesDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(
                at: templatesDirectory, withIntermediateDirectories: true)
            print("🎉 Initialization done!")
        }
    }
    struct Build: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Deletes the output directory if there is one and builds the site")

        func run() throws {
            let parser = MarkdownParser()
            let blueprint = Blueprint.Template()
            let fileManager = FileManager.default

            // Expected directories
            let contentDirectory = URL(fileURLWithPath: "content", isDirectory: true)
            let staticDirectory = URL(fileURLWithPath: "static", isDirectory: true)
            let stylesDirectory = URL(fileURLWithPath: "styles", isDirectory: true)
            let templatesDirectory = URL(fileURLWithPath: "templates", isDirectory: true)
            let outputDirectory = URL(fileURLWithPath: "public", isDirectory: true)

            // Remove old output and create a new directory
            try? fileManager.removeItem(at: outputDirectory)
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

            // Move all content from Static to Output
            let staticFiles = try fileManager.contentsOfDirectory(atPath: staticDirectory.path)
            for file in staticFiles {
                print(file)
                let currentFileURL = staticDirectory.appendingPathComponent(file)
                let outputFileURL = outputDirectory.appendingPathComponent(file)
                try fileManager.copyItem(at: currentFileURL, to: outputFileURL)
            }

            // Move all content from Styles to Output
            let stylesFiles = try fileManager.contentsOfDirectory(atPath: stylesDirectory.path)
            for file in stylesFiles {
                print(file)
                let currentFileURL = stylesDirectory.appendingPathComponent(file)
                let outputFileURL = outputDirectory.appendingPathComponent(file)
                try fileManager.copyItem(at: currentFileURL, to: outputFileURL)
            }

            // Get all markdown files in Content
            let markdownFiles = try fileManager.contentsOfDirectory(atPath: contentDirectory.path)
                .filter { $0.hasSuffix(".md") }

            for file in markdownFiles {
                let fileURL = contentDirectory.appendingPathComponent(file)
                let rawContent = try String(contentsOf: fileURL)

                // Get markdown
                let markdown = parser.parse(rawContent)

                // Assert that template was defined
                guard let fileTemplate = markdown.metadata["template"] else {
                    throw RuntimeError("Missing template in \(fileURL.path)")
                }

                // Assert that defined template exists
                let templateURL = templatesDirectory.appendingPathComponent(fileTemplate)
                guard fileManager.fileExists(atPath: templateURL.path) else {
                    throw RuntimeError("Template not found: \(templateURL.path)")
                }

                // Stringfy template
                let templateString = try String(contentsOf: templateURL)

                // Convert markdown to HTML using Ink
                let html = markdown.html

                // Build context
                var context: [String: Any] = [:]
                context["content"] = html
                // Converting all values to string, might lead to an issue
                for (key, value) in markdown.metadata {
                    context[key] = value
                }

                // Render using Blueprint
                let rendered = try blueprint.render(template: templateString, context: context)

                // Create the output file
                let outputFilename = file.replacingOccurrences(of: ".md", with: ".html")
                let outputPath = outputDirectory.appendingPathComponent(outputFilename)
                try rendered.write(to: outputPath, atomically: true, encoding: .utf8)

                print("✅ Built \(outputFilename)")
            }

            print("🎉 Build complete")
        }
    }
    struct Serve: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Serve the site. Rebuild and reload on change automatically")
        func run() throws {
            // Build the site
            try Build().run()

            let server = HttpServer()
            let publicPath = FileManager.default.currentDirectoryPath + "/public"

            print("📂 Serving files from: \(publicPath)")
            print("🌍 Starting server at http://localhost:8000")

            // Catch-all route
            server.middleware.append { request in
                var path = request.path

                // If root, serve index.html
                if path == "/" || path.isEmpty {
                    path = "/index"
                }

                // Remove trailing slash
                if path.hasSuffix("/") {
                    path = String(path.dropLast())
                }

                // Try to serve .html file matching path
                let filePath = "\(publicPath)\(path).html"
                if FileManager.default.fileExists(atPath: filePath),
                    let content = try? String(contentsOfFile: filePath)
                {
                    return HttpResponse.ok(.html(content))
                }

                // Fallback to static files (images, CSS, JS, etc.)
                let fullPath = publicPath + request.path
                if FileManager.default.fileExists(atPath: fullPath),
                    let data = try? Data(contentsOf: URL(fileURLWithPath: fullPath))
                {
                    return HttpResponse.raw(
                        200, "OK", [:],
                        { writer in
                            try writer.write(data)
                        })
                }

                // Not found
                return HttpResponse.notFound
            }

            try server.start(8000)
            RunLoop.main.run()
        }
    }
}
