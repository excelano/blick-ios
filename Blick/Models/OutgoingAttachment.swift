// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import UniformTypeIdentifiers

struct OutgoingAttachment: Identifiable {
    let id = UUID()
    let name: String
    let contentType: String
    let data: Data

    static let maxTotalBytes = 3_000_000

    init(name: String, contentType: String, data: Data) {
        self.name = name
        self.contentType = contentType
        self.data = data
    }

    init(fileURL url: URL) throws {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        self.init(name: url.lastPathComponent,
                  contentType: UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream",
                  data: try Data(contentsOf: url))
    }

    var sizeLabel: String {
        ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }
}
