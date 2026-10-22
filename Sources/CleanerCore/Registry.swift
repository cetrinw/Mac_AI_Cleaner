import Foundation

public struct ToolDefinition: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let paths: [String]
    public let apps: [String]
    public let environmentKey: String?
    public init(_ id: String, _ name: String, _ category: String, _ paths: [String], _ apps: [String] = [], environmentKey: String? = nil) {
        self.id = id; self.name = name; self.category = category; self.paths = paths; self.apps = apps; self.environmentKey = environmentKey
    }
}

/// Discovery hints, never deletion permissions. Unconfirmed paths stay read-only.
public enum Registry {
    public static let version = "2026.10.22-alpha.1"
    public static let tools: [ToolDefinition] = [
        .init("qoder", "Qoder", "Coding agents", [".qoder", "Library/Application Support/Qoder"], ["Qoder.app"], environmentKey: "QODER_CONFIG_DIR"),
        .init("opencode", "OpenCode", "Coding agents", [".local/share/opencode", ".cache/opencode", ".config/opencode"], ["OpenCode.app"]),
        .init("claude-code", "Claude Code", "Coding agents", [".claude"]),
        .init("codex", "OpenAI Codex", "Coding agents", [".codex", "Library/Application Support/Codex"], ["Codex.app"], environmentKey: "CODEX_HOME"),
        .init("cursor", "Cursor", "AI editors", [".cursor", "Library/Application Support/Cursor", "Library/Caches/Cursor"], ["Cursor.app"]),
        .init("windsurf", "Windsurf", "AI editors", [".codeium/windsurf", "Library/Application Support/Windsurf"], ["Windsurf.app"]),
        .init("antigravity", "Antigravity", "AI editors", [".gemini/antigravity", "Library/Application Support/Antigravity"], ["Antigravity.app", "Antigravity IDE.app"]),
        .init("gemini", "Gemini CLI", "Coding agents", [".gemini"]),
        .init("copilot", "GitHub Copilot", "Coding agents", [".copilot", ".config/github-copilot"]),
        .init("trae", "Trae", "AI editors", [".trae", "Library/Application Support/Trae"], ["Trae.app"]),
        .init("kiro", "Kiro", "AI editors", [".kiro", "Library/Application Support/Kiro"], ["Kiro.app"]),
        .init("cline", "Cline", "Editor extensions", [".cline", "Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev"]),
        .init("roo", "Roo Code", "Editor extensions", ["Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline"]),
        .init("kilo", "Kilo Code", "Editor extensions", ["Library/Application Support/Code/User/globalStorage/kilocode.kilo-code"]),
        .init("continue", "Continue", "Editor extensions", [".continue"]),
        .init("aider", "Aider", "Coding agents", [".aider.conf.yml"]),
        .init("qwen", "Qwen Code", "Coding agents", [".qwen"]),
        .init("kimi", "Kimi Code", "Coding agents", [".kimi"]),
        .init("goose", "Goose", "Coding agents", [".config/goose", ".local/share/goose"]),
        .init("amp", "Amp", "Coding agents", [".config/amp", ".local/share/amp"]),
        .init("factory", "Factory Droid", "Coding agents", [".factory"]),
        .init("openhands", "OpenHands", "Coding agents", [".openhands"]),
        .init("junie", "JetBrains Junie", "Editor extensions", [".junie"]),
        .init("jetbrains", "JetBrains AI", "AI editors", ["Library/Application Support/JetBrains"]),
        .init("cody", "Sourcegraph Cody", "Editor extensions", ["Library/Application Support/Code/User/globalStorage/sourcegraph.cody-ai"]),
        .init("warp", "Warp", "AI editors", [".warp", "Library/Application Support/dev.warp.Warp-Stable"], ["Warp.app"]),
        .init("zed", "Zed", "AI editors", [".config/zed", "Library/Application Support/Zed"], ["Zed.app"]),
        .init("ollama", "Ollama", "Local models", [".ollama"], ["Ollama.app"], environmentKey: "OLLAMA_MODELS"),
        .init("lmstudio", "LM Studio", "Local models", [".lmstudio", ".cache/lm-studio", "Library/Application Support/LM Studio"], ["LM Studio.app"]),
        .init("huggingface", "Hugging Face", "Local models", [".cache/huggingface"], environmentKey: "HF_HOME"),
        .init("mlx", "MLX", "Local models", [".cache/mlx"]),
        .init("llamacpp", "llama.cpp", "Local models", ["Library/Caches/llama.cpp", ".cache/llama.cpp"]),
        .init("gpt4all", "GPT4All", "Local models", ["Library/Application Support/nomic.ai/GPT4All"], ["GPT4All.app"]),
        .init("jan", "Jan", "Local models", ["jan", "Library/Application Support/Jan"], ["Jan.app"]),
        .init("msty", "Msty", "Local models", ["Library/Application Support/Msty"], ["Msty.app"]),
        .init("anythingllm", "AnythingLLM", "Local models", ["Library/Application Support/anythingllm-desktop"], ["AnythingLLM.app"]),
        .init("openwebui", "Open WebUI", "Local models", [".open-webui"]),
        .init("comfyui", "ComfyUI", "Generative AI", ["Library/Application Support/ComfyUI"], ["ComfyUI.app"]),
        .init("invoke", "InvokeAI", "Generative AI", ["invokeai"]),
        .init("drawthings", "Draw Things", "Generative AI", ["Library/Containers/com.liuliu.draw-things"], ["Draw Things.app"]),
        .init("chatgpt", "ChatGPT", "AI desktop", ["Library/Application Support/com.openai.chat", "Library/Containers/com.openai.chat"], ["ChatGPT.app"]),
        .init("claude", "Claude Desktop", "AI desktop", ["Library/Application Support/Claude"], ["Claude.app"]),
        .init("perplexity", "Perplexity", "AI desktop", ["Library/Containers/ai.perplexity.mac"], ["Perplexity.app"]),
        .init("raycast", "Raycast", "AI desktop", ["Library/Application Support/com.raycast.macos"], ["Raycast.app"]),
        .init("cherry", "Cherry Studio", "AI desktop", ["Library/Application Support/CherryStudio"], ["Cherry Studio.app"]),
        .init("chatbox", "Chatbox", "AI desktop", ["Library/Application Support/xyz.chatboxapp.app"], ["Chatbox.app"]),
        .init("lobechat", "LobeChat", "AI desktop", ["Library/Application Support/LobeHub"], ["LobeHub.app"]),
        .init("xcode", "Xcode", "Development", ["Library/Developer/Xcode/DerivedData"], ["Xcode.app"]),
        .init("homebrew", "Homebrew", "Development", ["Library/Caches/Homebrew"]),
        .init("docker", "Docker", "Development", ["Library/Containers/com.docker.docker"], ["Docker.app"]),
        .init("npm", "npm", "Development", [".npm"]),
        .init("pip", "Python / pip", "Development", ["Library/Caches/pip"])
    ]

    public static func roots(for tool: ToolDefinition, home: URL, environment: [String: String]) -> [URL] {
        var paths = tool.paths.map { home.appendingPathComponent($0) }
        if tool.id == "opencode" {
            for (key, fallback) in [("XDG_DATA_HOME", ".local/share"), ("XDG_CACHE_HOME", ".cache"), ("XDG_CONFIG_HOME", ".config")] {
                let base = environment[key].flatMap { $0.hasPrefix("/") ? URL(fileURLWithPath: $0) : nil } ?? home.appendingPathComponent(fallback)
                paths.append(base.appendingPathComponent("opencode"))
            }
        }
        if let key = tool.environmentKey, let value = environment[key], value.hasPrefix("/") { paths.append(URL(fileURLWithPath: value)) }
        return Array(Set(paths.map { $0.standardizedFileURL })).sorted { $0.path < $1.path }
    }
}
