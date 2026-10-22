import XCTest
@testable import CleanerCore

final class ScannerTests: XCTestCase {
    func testRegistryHasAtLeastFortyDiscoveryDefinitions() { XCTAssertGreaterThanOrEqual(Registry.tools.count, 40) }
    func testProtectedPathsNeverBecomeCleanable() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".codex"), withIntermediateDirectories: true)
        try Data("session metadata".utf8).write(to: root.appendingPathComponent(".codex/session.json"))
        let report = Scanner(home: root, environment: [:], applicationDirectories: [], maxEntries: 1000).scan(tools: Registry.tools.filter { $0.id == "codex" })
        XCTAssertEqual(report.findings.count, 1); XCTAssertEqual(report.findings[0].risk, .protected); XCTAssertFalse(report.findings[0].cleanable); XCTAssertGreaterThan(report.findings[0].bytes, 0)
        try? FileManager.default.removeItem(at: root)
    }
    func testSymlinkIsMeasuredAsProtectedAndNotFollowed() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); let target = root.appendingPathComponent("target")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true); try Data(repeating: 1, count: 10).write(to: target.appendingPathComponent("secret"))
        let link = root.appendingPathComponent(".ollama"); try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        let report = Scanner(home: root, environment: [:], applicationDirectories: [], maxEntries: 1000).scan(tools: Registry.tools.filter { $0.id == "ollama" })
        XCTAssertEqual(report.findings.count, 1); XCTAssertGreaterThan(report.findings[0].symbolicLinks, 0); XCTAssertEqual(report.findings[0].risk, .protected); XCTAssertEqual(report.findings[0].bytes, 0)
        try? FileManager.default.removeItem(at: root)
    }
    func testEnvironmentOverrideIsIncludedWithoutReadingContents() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let custom = root.appendingPathComponent("custom-opencode")
        try FileManager.default.createDirectory(at: custom, withIntermediateDirectories: true)
        try Data("config metadata".utf8).write(to: custom.appendingPathComponent("settings.json"))
        let tool = Registry.tools.first { $0.id == "opencode" }!
        let roots = Registry.roots(for: tool, home: root, environment: ["XDG_CONFIG_HOME": custom.path])
        XCTAssertTrue(roots.contains(custom.appendingPathComponent("opencode")) || roots.contains(custom))
        try? FileManager.default.removeItem(at: root)
    }
    func testScanLimitIsReportedAsIncomplete() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let dir = root.appendingPathComponent(".npm")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for index in 0..<5 { try Data(repeating: 1, count: index + 1).write(to: dir.appendingPathComponent("file\(index)")) }
        let report = Scanner(home: root, environment: [:], applicationDirectories: [], maxEntries: 2).scan(tools: Registry.tools.filter { $0.id == "npm" })
        XCTAssertTrue(report.findings.first?.incomplete == true)
        XCTAssertTrue(report.issues.contains { $0.contains("上限") })
        try? FileManager.default.removeItem(at: root)
    }
    func testCancellationStopsBeforeTraversal() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".codex"), withIntermediateDirectories: true)
        let report = Scanner(home: root, environment: [:], applicationDirectories: []).scan(tools: Registry.tools.filter { $0.id == "codex" }, cancelled: { true })
        XCTAssertTrue(report.cancelled); XCTAssertTrue(report.findings.isEmpty)
        try? FileManager.default.removeItem(at: root)
    }
}
