import Foundation

/// Coach basato su Claude tramite il proxy serverless. Riceve gli SSE dal proxy
/// e li riemette come frammenti di testo.
struct CloudCoach: CoachEngine {
    /// URL del proxy. Da configurare in `CoachConfiguration`.
    let endpoint: URL
    /// Identificativo anonimo e stabile del dispositivo, per il rate limit.
    let userId: String

    func reply(to messages: [CoachMessage], context: CoachContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: endpoint)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(RequestBody(
                        userId: userId,
                        userContext: context.summary(),
                        messages: messages.map {
                            .init(role: $0.role.rawValue, content: $0.text)
                        }
                    ))

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw CoachError.network("risposta non valida")
                    }
                    guard http.statusCode == 200 else {
                        throw CoachError.server(try await Self.errorMessage(from: bytes, status: http.statusCode))
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        guard line.hasPrefix("data: ") else {
                            // Le righe "event: error" sono seguite dalla loro "data:":
                            // l'errore viene quindi propagato dal ramo data sotto.
                            continue
                        }
                        let payload = String(line.dropFirst(6))
                        if let chunk = try? JSONDecoder().decode(Chunk.self, from: Data(payload.utf8)) {
                            if let errorText = chunk.error {
                                throw CoachError.server(errorText)
                            }
                            if let text = chunk.text {
                                continuation.yield(text)
                            }
                        }
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch let error as CoachError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(throwing: CoachError.network(error.localizedDescription))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func errorMessage(from bytes: URLSession.AsyncBytes, status: Int) async throws -> String {
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
        }
        if let decoded = try? JSONDecoder().decode([String: String].self, from: data),
           let message = decoded["error"] {
            return message
        }
        return String(localized: "Errore del server (codice \(status)).")
    }

    private struct RequestBody: Encodable {
        let userId: String
        let userContext: String
        let messages: [Message]
        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    private struct Chunk: Decodable {
        let text: String?
        let error: String?
    }
}
