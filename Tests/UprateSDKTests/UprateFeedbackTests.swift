import Testing
import Foundation
@testable import UprateSDK

extension SerializedTests {
    @Suite("UprateFeedback")
    struct UprateFeedbackTests {

        private func makeFeedback() async -> UprateFeedback {
            MockURLProtocol.reset()
            let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
            await client.setUserContext(UserContext(userId: "test_user"))
            let feedback = UprateFeedback(apiClient: client)
            feedback.collectDeviceMetadata = false
            return feedback
        }

        // MARK: - submit

        @Test("submit returns FeedbackResult")
        func submitSuccess() async throws {
            let feedback = await makeFeedback()
            MockURLProtocol.register(path: "feedback", statusCode: 201, json: """
            {
                "uuid": "fb-1",
                "rating": 4,
                "message": "Great app",
                "status": "received",
                "created_at": "2026-03-26T14:25:38+00:00"
            }
            """)

            let result = try await feedback.submit(message: "Great app", rating: 4)

            #expect(result.id == "fb-1")
            #expect(result.rating == 4)
            #expect(result.message == "Great app")
            #expect(result.status == "received")
        }

        @Test("submit with message only (no rating, no metadata)")
        func submitMessageOnly() async throws {
            let feedback = await makeFeedback()
            MockURLProtocol.register(path: "feedback", statusCode: 201, json: """
            {
                "uuid": "fb-2",
                "rating": null,
                "message": "Just feedback",
                "status": "received",
                "created_at": "2026-03-26T14:25:38+00:00"
            }
            """)

            let result = try await feedback.submit(message: "Just feedback")

            #expect(result.id == "fb-2")
            #expect(result.rating == nil)
        }

        @Test("submit uses POST method to /feedback")
        func submitMethod() async throws {
            let feedback = await makeFeedback()
            MockURLProtocol.register(path: "feedback", statusCode: 201, json: """
            {
                "uuid": "fb-1",
                "rating": null,
                "message": "Test",
                "status": "received",
                "created_at": "2026-03-26T14:25:38+00:00"
            }
            """)

            _ = try await feedback.submit(message: "Test")

            #expect(MockURLProtocol.lastRequest?.httpMethod == "POST")
            #expect(MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        }

        @Test("submit sends request body with metadata")
        func submitWithMetadata() async throws {
            let feedback = await makeFeedback()
            MockURLProtocol.register(path: "feedback", statusCode: 201, json: """
            {
                "uuid": "fb-1",
                "rating": 5,
                "message": "Test",
                "status": "received",
                "created_at": "2026-03-26T14:25:38+00:00"
            }
            """)

            _ = try await feedback.submit(
                message: "Test",
                rating: 5,
                metadata: ["screen": "checkout", "count": 42]
            )

            let body = MockURLProtocol.lastRequest?.httpBody
            #expect(body != nil)
            if let body {
                let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
                #expect(json?["message"] as? String == "Test")
                #expect(json?["rating"] as? Int == 5)
                let metadata = json?["metadata"] as? [String: Any]
                let custom = metadata?["custom"] as? [String: Any]
                #expect(custom?["screen"] as? String == "checkout")
                #expect(custom?["count"] as? Int == 42)
            }
        }

        // MARK: - Local validation

        @Test("submit with empty message throws validationError")
        func submitEmptyMessage() async {
            let feedback = await makeFeedback()

            do {
                _ = try await feedback.submit(message: "")
                Issue.record("Expected validationError")
            } catch let error as UprateError {
                guard case .validationError(let msg, let errors) = error else {
                    Issue.record("Expected validationError, got \(error)")
                    return
                }
                #expect(msg == "The message field is required.")
                #expect(errors["message"] != nil)
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test("submit with message over 5000 chars throws validationError")
        func submitMessageTooLong() async {
            let feedback = await makeFeedback()
            let longMessage = String(repeating: "a", count: 5001)

            do {
                _ = try await feedback.submit(message: longMessage)
                Issue.record("Expected validationError")
            } catch let error as UprateError {
                guard case .validationError(let msg, _) = error else {
                    Issue.record("Expected validationError, got \(error)")
                    return
                }
                #expect(msg.contains("5000"))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test("submit with rating 0 throws validationError")
        func submitRatingZero() async {
            let feedback = await makeFeedback()

            do {
                _ = try await feedback.submit(message: "Test", rating: 0)
                Issue.record("Expected validationError")
            } catch let error as UprateError {
                guard case .validationError(_, let errors) = error else {
                    Issue.record("Expected validationError, got \(error)")
                    return
                }
                #expect(errors["rating"] != nil)
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test("submit with rating 6 throws validationError")
        func submitRatingSix() async {
            let feedback = await makeFeedback()

            do {
                _ = try await feedback.submit(message: "Test", rating: 6)
                Issue.record("Expected validationError")
            } catch let error as UprateError {
                guard case .validationError(_, let errors) = error else {
                    Issue.record("Expected validationError, got \(error)")
                    return
                }
                #expect(errors["rating"] != nil)
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test("submit with valid ratings 1 and 5 does not throw locally")
        func submitValidRatingBounds() async throws {
            let feedback = await makeFeedback()
            MockURLProtocol.register(path: "feedback", statusCode: 201, json: """
            {"uuid": "fb-1", "rating": 1, "message": "Test", "status": "received", "created_at": "2026-03-26T14:25:38+00:00"}
            """)

            let result1 = try await feedback.submit(message: "Test", rating: 1)
            #expect(result1.rating == 1)

            MockURLProtocol.register(path: "feedback", statusCode: 201, json: """
            {"uuid": "fb-2", "rating": 5, "message": "Test", "status": "received", "created_at": "2026-03-26T14:25:38+00:00"}
            """)

            let result5 = try await feedback.submit(message: "Test", rating: 5)
            #expect(result5.rating == 5)
        }

        // MARK: - getMySubmissions

        @Test("getMySubmissions returns array of FeedbackSubmission")
        func getMySubmissions() async throws {
            let feedback = await makeFeedback()
            MockURLProtocol.register(path: "feedback", statusCode: 200, json: """
            {
                "feedback": [
                    {
                        "uuid": "fb-1",
                        "rating": 4,
                        "message": "Good app",
                        "sentiment": "positive",
                        "created_at": "2026-03-26T14:25:38+00:00"
                    },
                    {
                        "uuid": "fb-2",
                        "rating": null,
                        "message": "Crashes often",
                        "sentiment": "negative",
                        "created_at": "2026-03-26T14:20:00+00:00"
                    }
                ]
            }
            """)

            let submissions = try await feedback.getMySubmissions()

            #expect(submissions.count == 2)
            #expect(submissions[0].id == "fb-1")
            #expect(submissions[0].sentiment == "positive")
            #expect(submissions[1].rating == nil)
        }

        @Test("getMySubmissions with empty list")
        func getMySubmissionsEmpty() async throws {
            let feedback = await makeFeedback()
            MockURLProtocol.register(path: "feedback", statusCode: 200, json: """
            {"feedback": []}
            """)

            let submissions = try await feedback.getMySubmissions()

            #expect(submissions.isEmpty)
        }

        @Test("getMySubmissions uses GET method")
        func getMySubmissionsMethod() async throws {
            let feedback = await makeFeedback()
            MockURLProtocol.register(path: "feedback", statusCode: 200, json: """
            {"feedback": []}
            """)

            _ = try await feedback.getMySubmissions()

            #expect(MockURLProtocol.lastRequest?.httpMethod == "GET")
        }

        // MARK: - Error handling

        @Test("submit with 429 throws rateLimited")
        func submitRateLimited() async {
            let feedback = await makeFeedback()
            MockURLProtocol.register(
                path: "feedback",
                statusCode: 429,
                json: #"{"message": "Too Many Attempts."}"#,
                headers: ["Retry-After": "60"]
            )

            do {
                _ = try await feedback.submit(message: "Test")
                Issue.record("Expected rateLimited")
            } catch let error as UprateError {
                guard case .rateLimited(let retryAfter) = error else {
                    Issue.record("Expected rateLimited, got \(error)")
                    return
                }
                #expect(retryAfter == 60.0)
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        // MARK: - collectDeviceMetadata

        @Test("collectDeviceMetadata false omits device key from body")
        func deviceMetadataDisabled() async throws {
            let feedback = await makeFeedback()
            feedback.collectDeviceMetadata = false
            MockURLProtocol.register(path: "feedback", statusCode: 201, json: """
            {"uuid": "fb-1", "rating": null, "message": "Test", "status": "received", "created_at": "2026-03-26T14:25:38+00:00"}
            """)

            _ = try await feedback.submit(message: "Test")

            let body = MockURLProtocol.lastRequest?.httpBody
            #expect(body != nil)
            if let body {
                let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
                let metadata = json?["metadata"] as? [String: Any]
                // metadata should be nil (no device, no custom)
                #expect(metadata == nil)
            }
        }

        @Test("collectDeviceMetadata true includes device key in body")
        func deviceMetadataEnabled() async throws {
            MockURLProtocol.reset()
            let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
            await client.setUserContext(UserContext(userId: "test_user"))
            let feedback = UprateFeedback(apiClient: client)
            feedback.collectDeviceMetadata = true

            MockURLProtocol.register(path: "feedback", statusCode: 201, json: """
            {"uuid": "fb-1", "rating": null, "message": "Test", "status": "received", "created_at": "2026-03-26T14:25:38+00:00"}
            """)

            _ = try await feedback.submit(message: "Test")

            let body = MockURLProtocol.lastRequest?.httpBody
            #expect(body != nil)
            if let body {
                let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
                let metadata = json?["metadata"] as? [String: Any]
                #expect(metadata?["device"] != nil)
            }
        }
    }
}
