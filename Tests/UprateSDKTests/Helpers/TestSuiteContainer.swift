import Testing

/// A top-level serialized container that ensures all test suites using MockURLProtocol
/// run serially to prevent cross-suite interference with shared mock state.
@Suite(.serialized)
struct SerializedTests {}
