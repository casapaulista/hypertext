// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Blueprint
import Foundation
import Syntax
import Thread

// MARK: - Constants

enum Directories {
    static let contentURL = URL(fileURLWithPath: "content", isDirectory: true)
    static let staticURL = URL(fileURLWithPath: "static", isDirectory: true)
    static let stylesURL = URL(fileURLWithPath: "styles", isDirectory: true)
    static let templatesURL = URL(fileURLWithPath: "templates", isDirectory: true)
    static let outputURL = URL(fileURLWithPath: "public", isDirectory: true)
}

// MARK: - Error structs

// Hypertext's custom runtime error
struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}

// MARK: - Hypertext application

// Command settings
@main
struct Hypertext: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hx",
        abstract: "An elegant static site generator",
        subcommands: [Init.self, Build.self, Serve.self]
    )
}

// Subcommands
extension Hypertext {
    // MARK: - Init command
    struct Init: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Create a new project")
        func run() throws {
            try FileManager.default.createDirectory(
                at: Directories.contentURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(
                at: Directories.staticURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(
                at: Directories.stylesURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(
                at: Directories.templatesURL, withIntermediateDirectories: true)

            print("🎉 Setup complete!")
        }
    }

    // MARK: - Build command
    struct Build: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Deletes the output directory if there is one and builds the site")

        func recreateOutputDirectory() {
            try? FileManager.default.removeItem(at: Directories.outputURL)
            try? FileManager.default.createDirectory(
                at: Directories.outputURL, withIntermediateDirectories: true)
        }

        func collectMarkdownFiles(in directoryURL: URL) throws -> [URL] {
            var markdownFiles: [URL] = []

            if let enumerator = FileManager.default.enumerator(
                at: directoryURL, includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles])
            {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "md" {
                        markdownFiles.append(fileURL)
                    }
                }
            }

            return markdownFiles
        }

        func copyContentToOutput(directoryURL: URL) throws {
            let files = try FileManager.default.contentsOfDirectory(
                at: directoryURL, includingPropertiesForKeys: nil)

            for file in files {
                try FileManager.default.copyItem(
                    at: file,
                    to: Directories.outputURL.appendingPathComponent(file.lastPathComponent)
                )
            }
        }

        func getTemplateURL(parsedContent: Markdown, fileURL: URL) throws -> URL {
            // Assert that template was defined
            guard let template = parsedContent.metadata["template"] else {
                throw RuntimeError("Missing template in \(fileURL.path)")
            }
            let templateURL = Directories.templatesURL.appendingPathComponent(template)
            // Assert that defined template exists
            guard FileManager.default.fileExists(atPath: templateURL.path) else {
                throw RuntimeError("Template not found: \(templateURL.path)")
            }

            return templateURL
        }

        func getContext(parsedContent: Markdown) -> [String: String] {
            var context: [String: String] = [:]
            context["content"] = parsedContent.html
            for (key, value) in parsedContent.metadata {
                context[key] = value
            }

            return context
        }

        func writeHTMLFile(from content: String, relativePath: String) throws {
            let outputFilePath = Directories.outputURL
                .appendingPathComponent(relativePath)
                .deletingPathExtension()
                .appendingPathExtension("html")

            let outputDirectory = outputFilePath.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: outputDirectory, withIntermediateDirectories: true)

            try content.write(to: outputFilePath, atomically: true, encoding: .utf8)
        }

        func run() throws {
            recreateOutputDirectory()
            let parser = MarkdownParser()

            // Copy static and style assets
            try copyContentToOutput(directoryURL: Directories.staticURL)
            try copyContentToOutput(directoryURL: Directories.stylesURL)

            // Process all Markdown files recursively
            let markdownFiles = try collectMarkdownFiles(in: Directories.contentURL)

            for fileURL in markdownFiles {
                let markdown = try String(contentsOf: fileURL)
                let parsed = parser.parse(markdown)

                let templateURL = try getTemplateURL(parsedContent: parsed, fileURL: fileURL)
                let template = try String(contentsOf: templateURL)

                let context = getContext(parsedContent: parsed)
                let rendered = try Template(string: template).render(Box(context))

                // Calculate relative path for output
                let relativePath = fileURL.path.replacingOccurrences(
                    of: Directories.contentURL.path + "/", with: ""
                )

                try writeHTMLFile(from: rendered, relativePath: relativePath)
            }

            print("🎉 Build complete")
        }

    }

    // MARK: - Serve command
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

                // Handle root or any directory request
                if path.isEmpty || path.hasSuffix("/") {
                    path += "index"
                }

                // Attempt to serve .html version first
                let htmlPath = "\(publicPath)\(path).html"
                if let htmlData = try? Data(contentsOf: URL(fileURLWithPath: htmlPath)),
                    let htmlContent = String(data: htmlData, encoding: .utf8)
                {
                    return .ok(.html(htmlContent))
                }

                // Attempt to serve as a static file (CSS, JS, images, etc.)
                let staticPath = publicPath + request.path
                if let data = try? Data(contentsOf: URL(fileURLWithPath: staticPath)) {
                    return .raw(200, "OK", [:]) { writer in
                        try writer.write(data)
                    }
                }

                // File not found
                return .notFound()
            }

            try server.start(8000)
            RunLoop.main.run()
        }
    }
}
