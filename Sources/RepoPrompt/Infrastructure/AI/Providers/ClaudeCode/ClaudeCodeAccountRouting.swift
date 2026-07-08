import Foundation

enum ClaudeCodeAccountRouting {
    enum Route: String, Equatable {
        case orchestrator
        case worker
    }

    private enum AuthKind {
        case oauthToken
        case apiKey
        case authToken
    }

    private struct Credential {
        let kind: AuthKind
        let value: String
    }

    private static let sourceKeys: Set<String> = [
        "REPOPROMPT_CLAUDE_CODE_ORCHESTRATOR_OAUTH_TOKEN",
        "REPOPROMPT_CLAUDE_CODE_ORCHESTRATOR_API_KEY",
        "REPOPROMPT_CLAUDE_CODE_ORCHESTRATOR_AUTH_TOKEN",
        "REPOPROMPT_CLAUDE_CODE_WORKER_OAUTH_TOKEN",
        "REPOPROMPT_CLAUDE_CODE_WORKER_API_KEY",
        "REPOPROMPT_CLAUDE_CODE_WORKER_AUTH_TOKEN"
    ]

    private static let claudeAuthKeys: Set<String> = [
        "CLAUDE_CODE_OAUTH_TOKEN",
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_AUTH_TOKEN"
    ]

    static func routeForAgentSession(hasParentAgentSession: Bool) -> Route {
        hasParentAgentSession ? .worker : .orchestrator
    }

    static func environmentOverrides(
        for route: Route?,
        source: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        guard let credential = credential(for: route, source: source) else { return [:] }
        switch credential.kind {
        case .oauthToken:
            return ["CLAUDE_CODE_OAUTH_TOKEN": credential.value]
        case .apiKey:
            return ["ANTHROPIC_API_KEY": credential.value]
        case .authToken:
            return ["ANTHROPIC_AUTH_TOKEN": credential.value]
        }
    }

    static func removedEnvironmentKeys(
        for route: Route?,
        source: [String: String] = ProcessInfo.processInfo.environment
    ) -> Set<String> {
        var keys = sourceKeys
        guard let credential = credential(for: route, source: source) else { return keys }

        keys.formUnion(claudeAuthKeys)
        switch credential.kind {
        case .oauthToken:
            keys.remove("CLAUDE_CODE_OAUTH_TOKEN")
        case .apiKey:
            keys.remove("ANTHROPIC_API_KEY")
        case .authToken:
            keys.remove("ANTHROPIC_AUTH_TOKEN")
        }
        return keys
    }

    private static func credential(
        for route: Route?,
        source: [String: String]
    ) -> Credential? {
        guard let route else { return nil }
        switch route {
        case .orchestrator:
            return firstCredential(
                oauthTokenKey: "REPOPROMPT_CLAUDE_CODE_ORCHESTRATOR_OAUTH_TOKEN",
                apiKeyKey: "REPOPROMPT_CLAUDE_CODE_ORCHESTRATOR_API_KEY",
                authTokenKey: "REPOPROMPT_CLAUDE_CODE_ORCHESTRATOR_AUTH_TOKEN",
                source: source
            )
        case .worker:
            return firstCredential(
                oauthTokenKey: "REPOPROMPT_CLAUDE_CODE_WORKER_OAUTH_TOKEN",
                apiKeyKey: "REPOPROMPT_CLAUDE_CODE_WORKER_API_KEY",
                authTokenKey: "REPOPROMPT_CLAUDE_CODE_WORKER_AUTH_TOKEN",
                source: source
            )
        }
    }

    private static func firstCredential(
        oauthTokenKey: String,
        apiKeyKey: String,
        authTokenKey: String,
        source: [String: String]
    ) -> Credential? {
        if let value = nonEmptyValue(source[oauthTokenKey]) {
            return Credential(kind: .oauthToken, value: value)
        }
        if let value = nonEmptyValue(source[apiKeyKey]) {
            return Credential(kind: .apiKey, value: value)
        }
        if let value = nonEmptyValue(source[authTokenKey]) {
            return Credential(kind: .authToken, value: value)
        }
        return nil
    }

    private static func nonEmptyValue(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else {
            return nil
        }
        return trimmed
    }
}
