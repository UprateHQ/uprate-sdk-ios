import Testing
import Foundation
@testable import UprateSDK

extension SerializedTests {
@Suite("UprateRoadmap")
struct UprateRoadmapTests {

    private func makeRoadmap() async -> UprateRoadmap {
        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "test_user"))
        return UprateRoadmap(apiClient: client)
    }

    // MARK: - getItems

    @Test("getItems returns roadmap response")
    func getItems() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap", statusCode: 200, json: """
        {
            "settings": {
                "voting_enabled": true,
                "show_vote_count": true,
                "voting_excluded_statuses": ["done"]
            },
            "items": [
                {
                    "uuid": "item-1",
                    "title": "Dark Mode",
                    "description": "Add dark mode",
                    "status": "planned",
                    "status_label": "Planned",
                    "votes_count": 42,
                    "has_voted": true,
                    "voting_disabled": false
                }
            ]
        }
        """)

        let roadmap = await makeRoadmap()
        let result = try await roadmap.getItems()

        #expect(result.settings.votingEnabled == true)
        #expect(result.items.count == 1)
        #expect(result.items[0].id == "item-1")
        #expect(result.items[0].title == "Dark Mode")
        #expect(result.items[0].votesCount == 42)
        #expect(result.items[0].hasVoted == true)
    }

    @Test("getItems uses GET method")
    func getItemsMethod() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap", statusCode: 200, json: """
        {"settings": {"voting_enabled": true, "show_vote_count": true, "voting_excluded_statuses": []}, "items": []}
        """)

        let roadmap = await makeRoadmap()
        _ = try await roadmap.getItems()

        #expect(MockURLProtocol.lastRequest?.httpMethod == "GET")
    }

    // MARK: - vote

    @Test("vote returns VoteResult")
    func vote() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/items", statusCode: 200, json: """
        {"voted": true, "votes_count": 43}
        """)

        let roadmap = await makeRoadmap()
        let result = try await roadmap.vote(itemId: "item-1")

        #expect(result.voted == true)
        #expect(result.votesCount == 43)
    }

    @Test("vote uses POST method")
    func voteMethod() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/items", statusCode: 200, json: """
        {"voted": true, "votes_count": 43}
        """)

        let roadmap = await makeRoadmap()
        _ = try await roadmap.vote(itemId: "item-1")

        #expect(MockURLProtocol.lastRequest?.httpMethod == "POST")
        let path = MockURLProtocol.lastRequest?.url?.path(percentEncoded: false) ?? ""
        #expect(path.contains("roadmap/items/item-1/vote"))
    }

    // MARK: - removeVote

    @Test("removeVote returns VoteResult")
    func removeVote() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/items", statusCode: 200, json: """
        {"voted": false, "votes_count": 42}
        """)

        let roadmap = await makeRoadmap()
        let result = try await roadmap.removeVote(itemId: "item-1")

        #expect(result.voted == false)
        #expect(result.votesCount == 42)
    }

    @Test("removeVote uses DELETE method")
    func removeVoteMethod() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/items", statusCode: 200, json: """
        {"voted": false, "votes_count": 42}
        """)

        let roadmap = await makeRoadmap()
        _ = try await roadmap.removeVote(itemId: "item-1")

        #expect(MockURLProtocol.lastRequest?.httpMethod == "DELETE")
    }

    // MARK: - submitRequest

    @Test("submitRequest returns FeatureRequest")
    func submitRequest() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/requests", statusCode: 201, json: """
        {
            "uuid": "req-1",
            "title": "Export to PDF",
            "description": "Allow PDF export",
            "status": "pending",
            "created_at": "2026-03-26T10:17:33+00:00"
        }
        """)

        let roadmap = await makeRoadmap()
        let result = try await roadmap.submitRequest(title: "Export to PDF", description: "Allow PDF export")

        #expect(result.id == "req-1")
        #expect(result.title == "Export to PDF")
        #expect(result.status == "pending")
    }

    @Test("submitRequest sends POST with JSON body")
    func submitRequestMethod() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/requests", statusCode: 201, json: """
        {
            "uuid": "req-1",
            "title": "Test",
            "description": null,
            "status": "pending",
            "created_at": "2026-03-26T10:17:33+00:00"
        }
        """)

        let roadmap = await makeRoadmap()
        _ = try await roadmap.submitRequest(title: "Test", description: nil)

        let request = MockURLProtocol.lastRequest
        #expect(request?.httpMethod == "POST")
        #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    // MARK: - getMyRequests

    @Test("getMyRequests returns array of FeatureRequest")
    func getMyRequests() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/requests", statusCode: 200, json: """
        {
            "requests": [
                {
                    "uuid": "req-1",
                    "title": "Feature A",
                    "description": null,
                    "status": "pending",
                    "created_at": "2026-03-26T10:17:33+00:00"
                },
                {
                    "uuid": "req-2",
                    "title": "Feature B",
                    "description": "Details",
                    "status": "approved",
                    "created_at": "2026-03-26T11:00:00+00:00"
                }
            ]
        }
        """)

        let roadmap = await makeRoadmap()
        let requests = try await roadmap.getMyRequests()

        #expect(requests.count == 2)
        #expect(requests[0].title == "Feature A")
        #expect(requests[1].status == "approved")
    }

    @Test("getMyRequests uses GET method")
    func getMyRequestsMethod() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/requests", statusCode: 200, json: """
        {"requests": []}
        """)

        let roadmap = await makeRoadmap()
        _ = try await roadmap.getMyRequests()

        #expect(MockURLProtocol.lastRequest?.httpMethod == "GET")
    }

    // MARK: - Error cases

    @Test("vote on nonexistent item throws notFound")
    func voteNotFound() async {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/items", statusCode: 404, json: """
        {"message": "Roadmap item not found."}
        """)

        let roadmap = await makeRoadmap()

        await #expect(throws: UprateError.self) {
            try await roadmap.vote(itemId: "nonexistent")
        }
    }

    @Test("submitRequest with validation error throws validationError")
    func submitRequestValidation() async {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap/requests", statusCode: 422, json: """
        {"message": "The title field is required.", "errors": {"title": ["The title field is required."]}}
        """)

        let roadmap = await makeRoadmap()

        do {
            _ = try await roadmap.submitRequest(title: "", description: nil)
            Issue.record("Expected validationError")
        } catch let error as UprateError {
            guard case .validationError(let message, _) = error else {
                Issue.record("Expected validationError, got \(error)")
                return
            }
            #expect(message == "The title field is required.")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
} // extension SerializedTests
