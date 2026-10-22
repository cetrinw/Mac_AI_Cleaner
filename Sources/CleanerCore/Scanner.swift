import Foundation

public enum Risk: String, Codable, Sendable { case review = "B", protected = "C" }
public struct Finding: Identifiable, Codable, Sendable {
    public var id: String { path }
    public let toolID: String
    public let tool: String
    public let category: String
    public let path: String
    public let bytes: Int64
    public let files: Int
    public let risk: Risk
    public let reason: String
    public let incomplete: Bool
    public let issues: [String]
    public let hardLinks: Int
    public let symbolicLinks: Int
    public let modified: Date?
    public var cleanable: Bool { JunkPolicy.risk(for: URL(fileURLWithPath: path), home: FileManager.default.homeDirectoryForCurrentUser).0 == .review && risk == .review }
    public var impact: String { risk == .protected ? "可能包含会话、配置、认证、模型引用或用户成果。禁止自动清理。" : "需要核验工具版本、引用和进程；可能需要重新下载或构建。当前版本只读。" }
    public var recovery: String { "本次扫描未移动或删除文件，无需恢复。" }
}
public struct ScanReport: Codable, Sendable {
    public let date: Date
    public let ruleVersion: String
    public let findings: [Finding]
    public let installedApps: [String]
    public let issues: [String]
    public let cancelled: Bool
    public let availableBytes: Int64?
    public var totalBytes: Int64 { findings.reduce(0) { $0 + $1.bytes } }
    public var detectedTools: Int { Set(findings.map(\.toolID) + installedApps).count }
}

public struct LargeItem: Identifiable, Codable, Sendable {
    public var id: String { path }
    public let path: String
    public let name: String
    public let bytes: Int64
    public let isDirectory: Bool
    public let files: Int
    public let risk: Risk
    public let reason: String
    public var recoverable: Bool { risk == .review }
}
public struct DiskUsage: Codable, Sendable { public let totalBytes: Int64; public let freeBytes: Int64; public var usedBytes: Int64 { max(0, totalBytes - freeBytes) }; public var usedRatio: Double { totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0 } }

public enum JunkPolicy {
    public static func risk(for path: URL, home: URL) -> (Risk, String) {
        let p = path.standardizedFileURL.path
        let protected = [home.appendingPathComponent(".ssh").path, home.appendingPathComponent(".codex").path, home.appendingPathComponent(".claude").path, home.appendingPathComponent(".qoder").path, "/System", "/Library/Keychains", "/Applications"]
        if protected.contains(where: { p == $0 || p.hasPrefix($0 + "/") }) { return (.protected, "系统、凭证或 AI 工作数据，禁止清理。") }
        if p.contains("/Library/Caches/") || p.hasSuffix("/.cache") || p.contains("/.npm/") { return (.review, "缓存类路径，可移至废纸篓；仍需确认应用未运行。") }
        return (.protected, "未知文件用途，先展示不自动清理。")
    }
}

public enum CleanupExecutor {
    /// Moves only explicitly approved, recoverable items to the user's Trash.
    /// Protected and unknown paths are rejected before any filesystem operation.
    public static func moveToTrash(_ item: LargeItem, home: URL) throws {
        guard item.recoverable, item.risk == .review else { throw CocoaError(.userCancelled, userInfo: [NSLocalizedDescriptionKey: "此项目未通过安全清理策略。"] ) }
        let url = URL(fileURLWithPath: item.path).standardizedFileURL
        guard url.path.hasPrefix(home.path + "/Library/Caches/") || url.path.hasPrefix(home.path + "/.cache/") || url.path.hasPrefix(home.path + "/.npm/") else { throw CocoaError(.userCancelled, userInfo: [NSLocalizedDescriptionKey: "仅允许清理受限缓存目录。"] ) }
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }
    public static func moveFindingToTrash(_ finding: Finding, home: URL) throws {
        let url = URL(fileURLWithPath: finding.path).standardizedFileURL
        let policy = JunkPolicy.risk(for: url, home: home)
        guard finding.risk == .review, policy.0 == .review else { throw CocoaError(.userCancelled, userInfo: [NSLocalizedDescriptionKey: "该扫描结果未通过垃圾清理规则。"]) }
        guard url.path.hasPrefix(home.path + "/Library/Caches/") || url.path.hasPrefix(home.path + "/.cache/") || url.path.hasPrefix(home.path + "/.npm/") else { throw CocoaError(.userCancelled, userInfo: [NSLocalizedDescriptionKey: "仅允许清理受限缓存目录。"]) }
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }
}

public enum SafetyPolicy {
    public static func classify(tool: ToolDefinition, path: URL, linked: Bool) -> (Risk, String) {
        if linked { return (.protected, "符号链接或硬链接：引用关系未经核验。") }
        if tool.category == "Local models" || tool.category == "Generative AI" { return (.protected, "模型与共享对象可能被引用；路径名称不能证明可删除。") }
        if ["homebrew", "npm", "pip", "xcode"].contains(tool.id) { return (.review, "可重建性及占用进程尚未核验；仅供人工分析。") }
        return (.protected, "工具数据可能混合会话、密钥、配置及用户成果；默认保护。")
    }
}

public struct Scanner: Sendable {
    public let home: URL
    public let environment: [String: String]
    public let applicationDirectories: [URL]
    public let maxEntries: Int
    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser, environment: [String: String] = ProcessInfo.processInfo.environment, applicationDirectories: [URL] = [URL(fileURLWithPath: "/Applications")], maxEntries: Int = 250_000) {
        self.home = home.standardizedFileURL; self.environment = environment
        self.applicationDirectories = applicationDirectories; self.maxEntries = maxEntries
    }

    /// Searches common user, app-support and environment locations so custom tool directories are discoverable.
    public func discoverToolRoots(tools: [ToolDefinition] = Registry.tools) -> [(ToolDefinition, URL)] {
        let fm = FileManager.default
        var result: [(ToolDefinition, URL)] = []
        let homes = [home, home.appendingPathComponent("Library/Application Support"), home.appendingPathComponent("Library/Caches"), home.appendingPathComponent("Applications")]
        for tool in tools {
            let known = Set(Registry.roots(for: tool, home: home, environment: environment).map(\.standardizedFileURL.path))
            for root in known where fm.fileExists(atPath: root) { result.append((tool, URL(fileURLWithPath: root))) }
            for base in homes {
                guard let children = try? fm.contentsOfDirectory(at: base, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { continue }
                for child in children where tool.name.localizedCaseInsensitiveContains(child.lastPathComponent) || child.lastPathComponent.localizedCaseInsensitiveContains(tool.name) { result.append((tool, child)) }
            }
        }
        return Array(Set(result.map { "\($0.0.id)|\($0.1.path)" })).compactMap { key in
            let parts = key.split(separator: "|", maxSplits: 1).map(String.init); guard parts.count == 2, let tool = tools.first(where: { $0.id == parts[0] }) else { return nil }; return (tool, URL(fileURLWithPath: parts[1]))
        }.sorted { $0.1.path < $1.1.path }
    }

    public func scanLargeItems(roots: [URL] = [], minBytes: Int64 = 50 * 1024 * 1024, maxItems: Int = 200, cancelled: @Sendable () -> Bool = { false }, progress: @Sendable (String, Double) -> Void = { _, _ in }) -> [LargeItem] {
        let fm = FileManager.default
        // Keep the default scan inside user-owned cache/download locations. Do not touch
        // Applications, System, Desktop/Documents, Calendar or Contacts databases.
        let searchRoots = roots.isEmpty ? [home.appendingPathComponent("Library/Caches"), home.appendingPathComponent(".cache"), home.appendingPathComponent(".npm"), home.appendingPathComponent("Downloads")] : roots.filter { $0.path.hasPrefix(home.path + "/") }
        var items: [LargeItem] = []
        for (rootIndex, root) in searchRoots.enumerated() where fm.fileExists(atPath: root.path) {
            progress(root.path, Double(rootIndex) / Double(max(1, searchRoots.count)))
            guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey], options: [], errorHandler: { _, _ in true }) else { continue }
            for case let url as URL in enumerator {
                if cancelled() { return items.sorted { $0.bytes > $1.bytes }.prefix(maxItems).map { $0 } }
                guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]), values.isSymbolicLink != true else { enumerator.skipDescendants(); continue }
                if values.isRegularFile == true, let size = values.fileSize, Int64(size) >= minBytes { let r = JunkPolicy.risk(for: url, home: home); items.append(LargeItem(path: url.path, name: url.lastPathComponent, bytes: Int64(size), isDirectory: false, files: 1, risk: r.0, reason: r.1)) }
            }
        }
        progress("完成", 1); return Array(items.sorted { $0.bytes > $1.bytes }.prefix(maxItems))
    }
    public func diskUsage() -> DiskUsage { let attrs = try? FileManager.default.attributesOfFileSystem(forPath: home.path); return DiskUsage(totalBytes: (attrs?[.systemSize] as? NSNumber)?.int64Value ?? 0, freeBytes: (attrs?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0) }

    public func scan(tools: [ToolDefinition] = Registry.tools, cancelled: @Sendable () -> Bool = { false }, progress: @Sendable (String) -> Void = { _ in }) -> ScanReport {
        let fm = FileManager.default
        var findings: [Finding] = [], apps: [String] = [], issues: [String] = []
        var seenPaths = Set<String>(), seenFiles = Set<String>(), entries = 0
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey]
        // Cover parent roots first so nested roots cannot inflate the total.
        let roots = tools.flatMap { tool in Registry.roots(for: tool, home: home, environment: environment).map { (tool, $0) } }.sorted { $0.1.path.count < $1.1.path.count }
        for tool in tools {
            if applicationDirectories.contains(where: { directory in tool.apps.contains { fm.fileExists(atPath: directory.appendingPathComponent($0).path) } }) { apps.append(tool.id) }
        }
        for (tool, root) in roots {
            if cancelled() || entries >= maxEntries { break }
            if seenPaths.contains(where: { root.path == $0 || root.path.hasPrefix($0 + "/") }) { continue }
            let attrs: [FileAttributeKey: Any]
            do { attrs = try fm.attributesOfItem(atPath: root.path) }
            catch let error as NSError {
                if error.domain != NSCocoaErrorDomain || error.code != NSFileNoSuchFileError { issues.append("\(tool.name): \(error.localizedDescription)") }
                continue
            }
            seenPaths.insert(root.path); progress(tool.name)
            var size: Int64 = 0, count = 0, symlinks = 0, hardlinks = 0, rootIssues: [String] = []
            // Reject a root with any symlink ancestor. Never follow redirects out of an approved path.
            var ancestor = root
            var redirected = false
            while ancestor.path != "/" {
                if let a = try? fm.attributesOfItem(atPath: ancestor.path), a[.type] as? FileAttributeType == .typeSymbolicLink { redirected = true; break }
                ancestor.deleteLastPathComponent()
            }
            if redirected { symlinks += 1; rootIssues.append("跳过符号链接路径，不跟随目标。") }
            func measure(_ url: URL) {
                entries += 1
                do {
                    let values = try url.resourceValues(forKeys: Set(keys))
                    if values.isSymbolicLink == true { symlinks += 1; return }
                    guard values.isRegularFile == true else { return }
                    let a = try fm.attributesOfItem(atPath: url.path)
                    let identity = "\(a[.systemNumber] ?? "?"):\(a[.systemFileNumber] ?? url.path)"
                    if (a[.referenceCount] as? NSNumber)?.intValue ?? 1 > 1 { hardlinks += 1 }
                    guard seenFiles.insert(identity).inserted else { return }
                    count += 1; size += Int64(values.fileSize ?? 0)
                } catch { if rootIssues.count < 10 { rootIssues.append(error.localizedDescription) } }
            }
            if !redirected {
                if attrs[.type] as? FileAttributeType == .typeDirectory {
                    if let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: keys, options: [], errorHandler: { _, error in
                        if rootIssues.count < 10 { rootIssues.append(error.localizedDescription) }; return true
                    }) {
                        for case let url as URL in enumerator {
                            if cancelled() || entries >= maxEntries { rootIssues.append("扫描中断或达到文件数量上限；大小为已读部分。"); break }
                            // Foundation skips symlink directories; also explicitly skip descendants.
                            if (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true { enumerator.skipDescendants() }
                            measure(url)
                        }
                    } else { rootIssues.append("无法枚举目录。") }
                } else { measure(root) }
            }
            let (risk, reason) = SafetyPolicy.classify(tool: tool, path: root, linked: symlinks + hardlinks > 0)
            findings.append(Finding(toolID: tool.id, tool: tool.name, category: tool.category, path: root.path, bytes: size, files: count, risk: risk, reason: reason, incomplete: !rootIssues.isEmpty, issues: rootIssues, hardLinks: hardlinks, symbolicLinks: symlinks, modified: attrs[.modificationDate] as? Date))
        }
        if entries >= maxEntries { issues.append("达到 \(maxEntries) 个目录项上限；未扫描的数据不计入总量。") }
        let available = (try? fm.attributesOfFileSystem(forPath: home.path)[.systemFreeSize] as? NSNumber)?.int64Value
        return ScanReport(date: Date(), ruleVersion: Registry.version, findings: findings.sorted { $0.bytes > $1.bytes }, installedApps: apps, issues: issues, cancelled: cancelled(), availableBytes: available)
    }
}
