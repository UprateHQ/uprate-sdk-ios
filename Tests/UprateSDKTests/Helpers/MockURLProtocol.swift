import Foundation

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var mockResponses: [String: (Int, Data, [String: String])] = [:]
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static func reset() {
        mockResponses = [:]
        lastRequest = nil
    }

    static func register(path: String, statusCode: Int, json: String, headers: [String: String] = [:]) {
        mockResponses[path] = (statusCode, Data(json.utf8), headers)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        var captured = request
        // URLSession moves httpBody into httpBodyStream when passing to URLProtocol.
        // Reconstruct httpBody from the stream so tests can inspect it.
        if captured.httpBody == nil, let stream = captured.httpBodyStream {
            stream.open()
            var data = Data()
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while stream.hasBytesAvailable {
                let bytesRead = stream.read(&buffer, maxLength: bufferSize)
                if bytesRead > 0 {
                    data.append(contentsOf: buffer[..<bytesRead])
                }
            }
            stream.close()
            captured.httpBody = data
        }
        Self.lastRequest = captured
        let path = request.url?.path(percentEncoded: false) ?? ""

        if let (statusCode, data, headers) = Self.mockResponses.first(where: { path.contains($0.key) })?.value {
            var allHeaders = headers
            allHeaders["Content-Type"] = "application/json"

            if let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://test.example.com")!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: allHeaders
            ) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
            }
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension URLSession {
    static var mocked: URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
