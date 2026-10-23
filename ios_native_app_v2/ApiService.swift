import Foundation

class ApiService {
    static let shared = ApiService()
    private let baseURL = "https://yashswi.in/api/"
    
    private init() {}
   
enum ApiError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."

        case .noData:
            return "The server returned no data."

        case .decodingError:
            return "Unable to read the server response."

        case .serverError(let message):
            return message

        case .httpError(let statusCode):
            return "Server request failed. HTTP status: \(statusCode)"
        }
    }
}

    
    private func postRequest<T: Codable, U: Codable>(endpoint: String, requestData: T, completion: @escaping (Result<U, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(ApiError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
guard let httpResponse = response as? HTTPURLResponse else {
    DispatchQueue.main.async {
        completion(.failure(ApiError.serverError(
            "Invalid server response."
        )))
    }
    return
}

guard (200...299).contains(httpResponse.statusCode) else {
    DispatchQueue.main.async {
        completion(.failure(
            ApiError.httpError(httpResponse.statusCode)
        ))
    }
    return
}

            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(ApiError.noData)) }
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(U.self, from: data)
                DispatchQueue.main.async { completion(.success(decodedResponse)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(ApiError.decodingError)) }
            }
        }.resume()
    }
    
    // MARK: - Android-Compatible Login

    func performAndroidCompatibleLogin(
        empId: String,
        password: String,
        deviceId: String,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URL(
            string: "https://yashswi.in/auth/api_login.php"
        ) else {
            DispatchQueue.main.async {
                completion(.failure(ApiError.invalidURL))
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        let parameters = [
            "emp_id": empId,
            "password": password,
            "device_id": deviceId
        ]

        var components = URLComponents()
        components.queryItems = parameters.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }

        // Encode as form data, including spaces as +.
        let formBody = (components.percentEncodedQuery ?? "")
            .replacingOccurrences(of: "%20", with: "+")

        request.httpBody = formBody.data(using: .utf8)

      let configuration = URLSessionConfiguration.default
configuration.httpCookieStorage = HTTPCookieStorage.shared
configuration.httpShouldSetCookies = true
configuration.httpCookieAcceptPolicy = .always

let session = URLSession(configuration: configuration)

session.dataTask(with: request) {
    data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse =
                    response as? HTTPURLResponse else {
                    completion(.failure(
                        ApiError.serverError("Invalid server response.")
                    ))
                    return
                }

                guard (200...299).contains(
                    httpResponse.statusCode
                ) else {
                    completion(.failure(
                        ApiError.httpError(httpResponse.statusCode)
                    ))
                    return
                }

                guard let data = data, !data.isEmpty else {
                    completion(.failure(ApiError.noData))
                    return
                }

                completion(.success(data))
            }
        }.resume()
    }

    
    // MARK: - Endpoints
    
    func performLogin(request: LoginRequest, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        postRequest(endpoint: "native_login.php", requestData: request, completion: completion)
    }
    
    func submitAttendance(request: AttendanceRequest, completion: @escaping (Result<AttendanceResponse, Error>) -> Void) {
        postRequest(endpoint: "save_attendance.php", requestData: request, completion: completion)
    }
    
    func submitFsr(request: FsrRequest, completion: @escaping (Result<GenericResponse, Error>) -> Void) {
        postRequest(endpoint: "save_fsr.php", requestData: request, completion: completion)
    }
    
func getProducts(
    completion: @escaping (Result<ProductResponse, Error>) -> Void
) {
    guard let url = URL(string: baseURL + "get_products.php") else {
        DispatchQueue.main.async {
            completion(.failure(ApiError.invalidURL))
        }
        return
    }

    URLSession.shared.dataTask(with: url) { data, response, error in

        if let error = error {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            DispatchQueue.main.async {
                completion(.failure(
                    ApiError.serverError("Invalid server response.")
                ))
            }
            return
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            DispatchQueue.main.async {
                completion(.failure(
                    ApiError.httpError(httpResponse.statusCode)
                ))
            }
            return
        }

        guard let data = data else {
            DispatchQueue.main.async {
                completion(.failure(ApiError.noData))
            }
            return
        }

        do {
            let decodedResponse = try JSONDecoder().decode(
                ProductResponse.self,
                from: data
            )

            DispatchQueue.main.async {
                completion(.success(decodedResponse))
            }

        } catch {
            DispatchQueue.main.async {
                completion(.failure(ApiError.decodingError))
            }
        }

   
    }.resume()
}

}

