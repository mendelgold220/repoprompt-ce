@testable import RepoPrompt
import XCTest

final class ClaudeCodeAccountRoutingTests: XCTestCase {
    func testOrchestratorOAuthTokenIsMappedAndSourceSecretsAreRemoved() {
        let source = [
            "REPOPROMPT_CLAUDE_CODE_ORCHESTRATOR_OAUTH_TOKEN": "orchestrator-token",
            "REPOPROMPT_CLAUDE_CODE_WORKER_OAUTH_TOKEN": "worker-token",
            "ANTHROPIC_API_KEY": "ambient-api-key"
        ]

        XCTAssertEqual(
            ClaudeCodeAccountRouting.environmentOverrides(for: .orchestrator, source: source),
            ["CLAUDE_CODE_OAUTH_TOKEN": "orchestrator-token"]
        )

        let removed = ClaudeCodeAccountRouting.removedEnvironmentKeys(for: .orchestrator, source: source)
        XCTAssertTrue(removed.contains("REPOPROMPT_CLAUDE_CODE_ORCHESTRATOR_OAUTH_TOKEN"))
        XCTAssertTrue(removed.contains("REPOPROMPT_CLAUDE_CODE_WORKER_OAUTH_TOKEN"))
        XCTAssertTrue(removed.contains("ANTHROPIC_API_KEY"))
        XCTAssertFalse(removed.contains("CLAUDE_CODE_OAUTH_TOKEN"))
    }

    func testWorkerAPIKeyRemovesConflictingClaudeAuthKeys() {
        let source = [
            "REPOPROMPT_CLAUDE_CODE_WORKER_API_KEY": "worker-api-key",
            "CLAUDE_CODE_OAUTH_TOKEN": "ambient-oauth-token",
            "ANTHROPIC_AUTH_TOKEN": "ambient-auth-token"
        ]

        XCTAssertEqual(
            ClaudeCodeAccountRouting.environmentOverrides(for: .worker, source: source),
            ["ANTHROPIC_API_KEY": "worker-api-key"]
        )

        let removed = ClaudeCodeAccountRouting.removedEnvironmentKeys(for: .worker, source: source)
        XCTAssertTrue(removed.contains("CLAUDE_CODE_OAUTH_TOKEN"))
        XCTAssertTrue(removed.contains("ANTHROPIC_AUTH_TOKEN"))
        XCTAssertFalse(removed.contains("ANTHROPIC_API_KEY"))
    }
}
