// BlickGraphTests.swift
// BlickGraphTests
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Testing
@testable import BlickGraph

struct BlickGraphTests {
    @Test func aMissingItemIsNotFound() {
        let missing = GraphError.httpError(method: "PATCH", path: "/me/messages/e1", status: 404, body: "")
        let refused = GraphError.httpError(method: "PATCH", path: "/me/messages/e1", status: 503, body: "")
        #expect(missing.isNotFound)
        #expect(!refused.isNotFound)
        #expect(!GraphError.invalidResponse.isNotFound)
    }
}
