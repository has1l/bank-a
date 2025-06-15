import Foundation

class AuthService {
    static let shared = AuthService()
    private let baseURL = "http://localhost:3001"

    func login(name: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/login") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["name": name, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            do {
                let response = try JSONDecoder().decode(AuthResponse.self, from: data)
                if response.success {
                    completion(.success(response.user))
                } else {
                    completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func register(name: String, phone: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/register") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["name": name, "phone": phone, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            do {
                let response = try JSONDecoder().decode(RegistrationResponse.self, from: data)
                if response.success {
                    completion(.success(response.message))
                } else {
                    completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let user: User
}

struct RegistrationResponse: Codable {
    let success: Bool
    let message: String
}