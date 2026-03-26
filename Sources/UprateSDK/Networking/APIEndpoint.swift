import Foundation

struct APIEndpoint: Sendable {
    let method: HTTPMethod
    let path: String
    private let _body: (@Sendable () throws -> Data)?

    init<Body: Encodable & Sendable>(method: HTTPMethod, path: String, body: Body?) {
        self.method = method
        self.path = path
        if let body {
            self._body = { try JSONEncoder().encode(body) }
        } else {
            self._body = nil
        }
    }

    init(method: HTTPMethod, path: String) {
        self.method = method
        self.path = path
        self._body = nil
    }

    var bodyData: Data? {
        get throws { try _body?() }
    }

    enum HTTPMethod: String, Sendable {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }
}
