import Testing
import Foundation
@testable import UprateSDK

@Suite("Model Decoding")
struct ModelDecodingTests {

    // MARK: - RoadmapItem

    @Test("decodes RoadmapItem with all fields")
    func decodesRoadmapItemFull() throws {
        let json = """
        {
            "uuid": "94aad8ef-54e9-4d47-871c-7756d01e8aee",
            "title": "Dark Mode Support",
            "description": "Add dark mode theme across the entire app",
            "status": "planned",
            "status_label": "Planned",
            "votes_count": 42,
            "has_voted": true,
            "voting_disabled": false
        }
        """
        let item = try JSONDecoder.uprate.decode(RoadmapItem.self, from: Data(json.utf8))
        #expect(item.id == "94aad8ef-54e9-4d47-871c-7756d01e8aee")
        #expect(item.title == "Dark Mode Support")
        #expect(item.description == "Add dark mode theme across the entire app")
        #expect(item.status == "planned")
        #expect(item.statusLabel == "Planned")
        #expect(item.votesCount == 42)
        #expect(item.hasVoted == true)
        #expect(item.votingDisabled == false)
    }

    @Test("decodes RoadmapItem with null description and missing votes_count")
    func decodesRoadmapItemMinimal() throws {
        let json = """
        {
            "uuid": "abc-123",
            "title": "Feature X",
            "description": null,
            "status": "in_progress",
            "status_label": "In Progress",
            "has_voted": false,
            "voting_disabled": true
        }
        """
        let item = try JSONDecoder.uprate.decode(RoadmapItem.self, from: Data(json.utf8))
        #expect(item.id == "abc-123")
        #expect(item.description == nil)
        #expect(item.votesCount == nil)
        #expect(item.hasVoted == false)
        #expect(item.votingDisabled == true)
    }

    @Test("decodes RoadmapItem with unknown status string")
    func decodesRoadmapItemUnknownStatus() throws {
        let json = """
        {
            "uuid": "abc-123",
            "title": "Feature X",
            "description": null,
            "status": "some_future_status",
            "status_label": "Some Future Status",
            "has_voted": false,
            "voting_disabled": false
        }
        """
        let item = try JSONDecoder.uprate.decode(RoadmapItem.self, from: Data(json.utf8))
        #expect(item.status == "some_future_status")
    }

    @Test("decodes RoadmapItem with extra unknown fields (forward compatibility)")
    func decodesRoadmapItemExtraFields() throws {
        let json = """
        {
            "uuid": "abc-123",
            "title": "Feature X",
            "description": null,
            "status": "planned",
            "status_label": "Planned",
            "has_voted": false,
            "voting_disabled": false,
            "some_new_field": "should be ignored",
            "another_field": 999
        }
        """
        let item = try JSONDecoder.uprate.decode(RoadmapItem.self, from: Data(json.utf8))
        #expect(item.id == "abc-123")
    }

    // MARK: - UprateRoadmapResponse

    @Test("decodes full roadmap response")
    func decodesRoadmapResponse() throws {
        let json = """
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
                    "votes_count": 10,
                    "has_voted": false,
                    "voting_disabled": false
                }
            ]
        }
        """
        let response = try JSONDecoder.uprate.decode(UprateRoadmapResponse.self, from: Data(json.utf8))
        #expect(response.settings.votingEnabled == true)
        #expect(response.settings.showVoteCount == true)
        #expect(response.settings.votingExcludedStatuses == ["done"])
        #expect(response.items.count == 1)
        #expect(response.items[0].title == "Dark Mode")
    }

    @Test("decodes roadmap response with empty items")
    func decodesRoadmapResponseEmpty() throws {
        let json = """
        {
            "settings": {
                "voting_enabled": false,
                "show_vote_count": false,
                "voting_excluded_statuses": []
            },
            "items": []
        }
        """
        let response = try JSONDecoder.uprate.decode(UprateRoadmapResponse.self, from: Data(json.utf8))
        #expect(response.settings.votingEnabled == false)
        #expect(response.items.isEmpty)
    }

    // MARK: - VoteResult

    @Test("decodes VoteResult")
    func decodesVoteResult() throws {
        let json = #"{"voted": true, "votes_count": 43}"#
        let result = try JSONDecoder.uprate.decode(VoteResult.self, from: Data(json.utf8))
        #expect(result.voted == true)
        #expect(result.votesCount == 43)
    }

    // MARK: - FeatureRequest

    @Test("decodes FeatureRequest with all fields")
    func decodesFeatureRequest() throws {
        let json = """
        {
            "uuid": "79fd9e1b-709e-4bf7-b672-fe42611e29f9",
            "title": "Export ride history to PDF",
            "description": "Allow downloading ride history as PDF for expense reports",
            "status": "pending",
            "created_at": "2026-03-26T10:17:33+00:00"
        }
        """
        let result = try JSONDecoder.uprate.decode(FeatureRequest.self, from: Data(json.utf8))
        #expect(result.id == "79fd9e1b-709e-4bf7-b672-fe42611e29f9")
        #expect(result.title == "Export ride history to PDF")
        #expect(result.description == "Allow downloading ride history as PDF for expense reports")
        #expect(result.status == "pending")
    }

    @Test("decodes FeatureRequest with null description")
    func decodesFeatureRequestNullDescription() throws {
        let json = """
        {
            "uuid": "abc-123",
            "title": "Quick feature",
            "description": null,
            "status": "approved",
            "created_at": "2026-03-26T10:17:33+00:00"
        }
        """
        let result = try JSONDecoder.uprate.decode(FeatureRequest.self, from: Data(json.utf8))
        #expect(result.description == nil)
        #expect(result.status == "approved")
    }

    @Test("decodes FeatureRequest with unknown status")
    func decodesFeatureRequestUnknownStatus() throws {
        let json = """
        {
            "uuid": "abc-123",
            "title": "Quick feature",
            "description": null,
            "status": "new_status_from_future",
            "created_at": "2026-03-26T10:17:33+00:00"
        }
        """
        let result = try JSONDecoder.uprate.decode(FeatureRequest.self, from: Data(json.utf8))
        #expect(result.status == "new_status_from_future")
    }

    // MARK: - FeatureRequestListResponse

    @Test("decodes feature request list response")
    func decodesFeatureRequestList() throws {
        let json = """
        {
            "requests": [
                {
                    "uuid": "req-1",
                    "title": "Feature A",
                    "description": null,
                    "status": "pending",
                    "created_at": "2026-03-26T10:17:33+00:00"
                }
            ]
        }
        """
        let response = try JSONDecoder.uprate.decode(FeatureRequestListResponse.self, from: Data(json.utf8))
        #expect(response.requests.count == 1)
        #expect(response.requests[0].title == "Feature A")
    }

    // MARK: - FeedbackResult

    @Test("decodes FeedbackResult with all fields")
    func decodesFeedbackResult() throws {
        let json = """
        {
            "uuid": "8f4597c0-f591-4d1d-970d-29c253ef8d6b",
            "rating": 4,
            "message": "Checkout is slow but overall great app",
            "status": "received",
            "created_at": "2026-03-26T14:25:38+00:00"
        }
        """
        let result = try JSONDecoder.uprate.decode(FeedbackResult.self, from: Data(json.utf8))
        #expect(result.id == "8f4597c0-f591-4d1d-970d-29c253ef8d6b")
        #expect(result.rating == 4)
        #expect(result.message == "Checkout is slow but overall great app")
        #expect(result.status == "received")
    }

    @Test("decodes FeedbackResult with null rating")
    func decodesFeedbackResultNullRating() throws {
        let json = """
        {
            "uuid": "abc-123",
            "rating": null,
            "message": "Just a message",
            "status": "received",
            "created_at": "2026-03-26T14:25:38+00:00"
        }
        """
        let result = try JSONDecoder.uprate.decode(FeedbackResult.self, from: Data(json.utf8))
        #expect(result.rating == nil)
    }

    // MARK: - FeedbackSubmission

    @Test("decodes FeedbackSubmission with sentiment")
    func decodesFeedbackSubmission() throws {
        let json = """
        {
            "uuid": "8f4597c0-f591-4d1d-970d-29c253ef8d6b",
            "rating": 4,
            "message": "Checkout is slow but overall great app",
            "sentiment": "mixed",
            "created_at": "2026-03-26T14:25:38+00:00"
        }
        """
        let submission = try JSONDecoder.uprate.decode(FeedbackSubmission.self, from: Data(json.utf8))
        #expect(submission.id == "8f4597c0-f591-4d1d-970d-29c253ef8d6b")
        #expect(submission.sentiment == "mixed")
        #expect(submission.rating == 4)
    }

    @Test("decodes FeedbackSubmission with null sentiment and null rating")
    func decodesFeedbackSubmissionNulls() throws {
        let json = """
        {
            "uuid": "abc-123",
            "rating": null,
            "message": "Map crashes when zooming",
            "sentiment": null,
            "created_at": "2026-03-26T14:20:00+00:00"
        }
        """
        let submission = try JSONDecoder.uprate.decode(FeedbackSubmission.self, from: Data(json.utf8))
        #expect(submission.sentiment == nil)
        #expect(submission.rating == nil)
    }

    @Test("decodes FeedbackSubmission with extra unknown fields")
    func decodesFeedbackSubmissionExtraFields() throws {
        let json = """
        {
            "uuid": "abc-123",
            "rating": 5,
            "message": "Great app",
            "sentiment": "positive",
            "created_at": "2026-03-26T14:20:00+00:00",
            "some_future_field": "ignored"
        }
        """
        let submission = try JSONDecoder.uprate.decode(FeedbackSubmission.self, from: Data(json.utf8))
        #expect(submission.id == "abc-123")
    }

    // MARK: - FeedbackListResponse

    @Test("decodes FeedbackListResponse with multiple items")
    func decodesFeedbackList() throws {
        let json = """
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
        """
        let response = try JSONDecoder.uprate.decode(FeedbackListResponse.self, from: Data(json.utf8))
        #expect(response.feedback.count == 2)
        #expect(response.feedback[0].id == "fb-1")
        #expect(response.feedback[1].sentiment == "negative")
    }
}
