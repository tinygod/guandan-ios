import Foundation
import GuandanCore

// Minimal localhost HTTP server hosting the web table (single player).

let game = WebGame()
let port: UInt16 = 8848

func httpResponse(_ body: Data, type: String, status: String = "200 OK") -> Data {
    var head = "HTTP/1.1 \(status)\r\n"
    head += "Content-Type: \(type); charset=utf-8\r\n"
    head += "Content-Length: \(body.count)\r\n"
    head += "Cache-Control: no-store\r\nConnection: close\r\n\r\n"
    return head.data(using: .utf8)! + body
}

func json(_ obj: Any) -> Data {
    httpResponse(try! JSONSerialization.data(withJSONObject: obj), type: "application/json")
}

func handle(method: String, path: String, body: Data) -> Data {
    switch (method, path) {
    case ("GET", "/"):
        return httpResponse(pageHTML.data(using: .utf8)!, type: "text/html")
    case ("GET", "/state"):
        return json(game.stateJSON())
    case ("GET", "/hint"):
        return json(["ids": game.hint()])
    case ("POST", "/play"):
        let obj = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
        let ids = obj?["ids"] as? [String] ?? []
        return json(["error": game.humanPlay(ids: ids) ?? ""])
    case ("POST", "/pass"):
        return json(["error": game.humanPass() ?? ""])
    case ("POST", "/next"):
        if game.handResult != nil {
            if game.match.matchWinner != nil { game.reset() } else { game.startHand() }
        }
        return json(["ok": true])
    case ("POST", "/reset"):
        game.reset()
        return json(["ok": true])
    default:
        return httpResponse(Data("not found".utf8), type: "text/plain", status: "404 Not Found")
    }
}

// MARK: - socket loop

let sock = socket(AF_INET, SOCK_STREAM, 0)
var yes: Int32 = 1
setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
var addr = sockaddr_in()
addr.sin_family = sa_family_t(AF_INET)
addr.sin_port = port.bigEndian
addr.sin_addr.s_addr = inet_addr("127.0.0.1")
let bindResult = withUnsafePointer(to: &addr) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
    }
}
guard bindResult == 0 else {
    print("ERROR: port \(port) busy"); exit(1)
}
listen(sock, 16)
print("READY http://localhost:\(port)")

while true {
    let client = accept(sock, nil, nil)
    guard client >= 0 else { continue }

    var buffer = Data()
    var chunk = [UInt8](repeating: 0, count: 65536)
    // read headers (+ body if any)
    while true {
        let n = read(client, &chunk, chunk.count)
        if n <= 0 { break }
        buffer.append(contentsOf: chunk[0..<n])
        if let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)) {
            let header = String(data: buffer[..<headerEnd.lowerBound], encoding: .utf8) ?? ""
            let contentLength = header
                .components(separatedBy: "\r\n")
                .first { $0.lowercased().hasPrefix("content-length:") }
                .flatMap { Int($0.split(separator: ":")[1].trimmingCharacters(in: .whitespaces)) } ?? 0
            let bodyHave = buffer.count - headerEnd.upperBound
            if bodyHave >= contentLength { break }
        }
        if buffer.count > 1_000_000 { break }
    }

    if let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)),
       let requestLine = String(data: buffer[..<headerEnd.lowerBound], encoding: .utf8)?
           .components(separatedBy: "\r\n").first {
        let parts = requestLine.split(separator: " ")
        if parts.count >= 2 {
            let response = handle(method: String(parts[0]), path: String(parts[1]),
                                  body: buffer[headerEnd.upperBound...])
            response.withUnsafeBytes { _ = write(client, $0.baseAddress, response.count) }
        }
    }
    close(client)
}
