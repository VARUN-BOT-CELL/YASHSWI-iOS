import Foundation

// MARK: - Auth
struct LoginRequest: Codable {
    let empId: String
    let pass: String
    
    enum CodingKeys: String, CodingKey {
        case empId = "emp_id"
        case pass = "password"
    }
}

struct LoginResponse: Codable {
    let success: Bool
    let message: String
    let user: User?
}

struct User: Codable {
    let id: Int
    let name: String
    let empId: String
    let role: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, role
        case empId = "emp_id"
    }
}

// MARK: - Attendance
struct AttendanceRequest: Codable {
    let empId: String
    let photo: String
    let lat: String
    let lng: String
    let address: String
    let deviceTime: String
    
    enum CodingKeys: String, CodingKey {
        case lat, lng, address
        case empId = "emp_id"
        case photo = "photo_base64"
        case deviceTime = "device_time"
    }
}

struct AttendanceResponse: Codable {
    let success: Bool
    let type: String
    let message: String
}

// MARK: - FSR
struct FsrRequest: Codable {
    let empId: String
    let machineNo: String
    let engName: String
    let visitType: String
    let visitPurpose: String
    let hmr: Int
    let issueCust: String
    let issueEng: String
    let action: String
    let parts: String
    let photoHmr: String?
    let signature: String?
    
    enum CodingKeys: String, CodingKey {
        case hmr, signature
        case empId = "emp_id"
        case machineNo = "machine_no_full"
        case engName = "engineer_name"
        case visitType = "visit_type"
        case visitPurpose = "visit_purpose"
        case issueCust = "issue_customer"
        case issueEng = "issue_engineer"
        case action = "action_taken"
        case parts = "used_parts"
        case photoHmr = "photo_hmr"
    }
}

// MARK: - Products
struct ProductResponse: Codable {
    let success: Bool
    let data: [Product]
}

struct Product: Codable {
    let id: Int
    let name: String
    let category: String
    let description: String
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, description
        case imageUrl = "image_url"
    }
}

struct GenericResponse: Codable {
    let success: Bool
    let message: String
}
