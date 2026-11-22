//
//  SupabaseService.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import Foundation
import Combine
import Security

@MainActor
public final class SupabaseService: ObservableObject {
    public static let shared = SupabaseService()

    private let baseURL = URL(string: "https://yqspunzsrmdaocqnlaba.supabase.co")!
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlxc3B1bnpzcm1kYW9jcW5sYWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5NTY1OTksImV4cCI6MjEwNTUzMjU5OX0.vAN10z0WHdavVCI1uzHXDitKu7kzXPvwVHbTEFIO4vE"
    private let localProfileKey = "lucid_current_user_profile"
    private let localEmailKey = "lucid_cached_user_email"
    private let localUserIdKey = "lucid_cached_user_id"

    @Published public var currentProfile: UserProfile?

    private static let isoFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public init() {
        self.currentProfile = loadLocalProfile()
    }

    // MARK: - Date Helper
    private func parseDate(_ dateString: String?) -> Date {
        guard let dateString, !dateString.isEmpty else { return Date() }
        if let d = Self.isoFormatterWithFractional.date(from: dateString) {
            return d
        }
        if let d = Self.isoFormatterStandard.date(from: dateString) {
            return d
        }
        return Date()
    }

    // MARK: - Record Parser
    private func parseProfileRecord(_ record: [String: Any]) -> UserProfile {
        let id = (record["id"] as? String).flatMap(UUID.init) ?? UUID()
        let name = record["name"] as? String ?? ""
        let email = record["email"] as? String ?? ""
        let leftPower = (record["left_eye_power"] as? NSNumber)?.doubleValue ?? 0.0
        let rightPower = (record["right_eye_power"] as? NSNumber)?.doubleValue ?? 0.0
        let conditions = record["previous_conditions"] as? [String] ?? []
        let screenHours = (record["screen_time_numeric"] as? NSNumber)?.doubleValue ?? 6.0
        let actualHours = (record["device_activity_actual_hours"] as? NSNumber)?.doubleValue
        let activity = record["primary_activity"] as? String ?? "Coding & Reading"
        let peakTime = record["peak_fatigue_time"] as? String ?? "Late Day (5–8)"

        var recs: [String] = []
        var baselineScore = 70
        if let planSummary = record["plan_summary"] as? [String: Any] {
            recs = planSummary["recommended_exercises"] as? [String] ?? []
            baselineScore = planSummary["baseline_rest_score"] as? Int ?? 70
        }

        let createdAt = parseDate(record["created_at"] as? String)
        let updatedAt = parseDate(record["updated_at"] as? String)

        return UserProfile(
            id: id,
            name: name,
            email: email,
            leftEyePower: leftPower,
            rightEyePower: rightPower,
            hasGlassesOrContacts: abs(leftPower) > 0.1 || abs(rightPower) > 0.1,
            previousConditions: conditions,
            estimatedDailyScreenTimeHours: screenHours,
            actualDailyScreenTimeHours: actualHours,
            primaryActivity: activity,
            peakFatigueTime: peakTime,
            recommendedExerciseIds: recs,
            baselineRestScore: baselineScore,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - Auth Session (Keychain-backed)
    //
    // Real Supabase Auth replaces the old homegrown `users.password` column + client-side string
    // comparison (which stored passwords in plaintext and let the public anon key read every row).
    // Supabase Auth handles hashing/sessions server-side; we just hold the issued tokens.

    private enum KeychainKey {
        static let accessToken = "lucid.auth.accessToken"
        static let refreshToken = "lucid.auth.refreshToken"
        static let authUserId = "lucid.auth.userId"
    }

    private var accessToken: String? { Keychain.load(KeychainKey.accessToken) }
    private var refreshToken: String? { Keychain.load(KeychainKey.refreshToken) }
    public var authUserId: UUID? { Keychain.load(KeychainKey.authUserId).flatMap(UUID.init) }

    private func storeSession(accessToken: String, refreshToken: String, userId: String) {
        Keychain.save(KeychainKey.accessToken, accessToken)
        Keychain.save(KeychainKey.refreshToken, refreshToken)
        Keychain.save(KeychainKey.authUserId, userId)
    }

    private func clearSession() {
        Keychain.delete(KeychainKey.accessToken)
        Keychain.delete(KeychainKey.refreshToken)
        Keychain.delete(KeychainKey.authUserId)
    }

    /// Builds a request authorized as the signed-in user when a session exists, otherwise falls back
    /// to the anonymous key (guest profiles, pre-auth reads).
    private func authorizedRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken ?? apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// Exchanges the stored refresh token for a new access token. Best-effort — on failure the caller
    /// just proceeds with whatever token (or lack of one) it already has, matching this file's existing
    /// "degrade gracefully, never crash the UI over a network hiccup" style.
    private func refreshSessionIfNeeded() async {
        guard let refreshToken,
              let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=refresh_token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccess = json["access_token"] as? String,
              let newRefresh = json["refresh_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else { return }

        storeSession(accessToken: newAccess, refreshToken: newRefresh, userId: userId)
    }

    private func authErrorMessage(from data: Data, fallback: String) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return fallback }
        return (json["error_description"] as? String)
            ?? (json["msg"] as? String)
            ?? (json["message"] as? String)
            ?? fallback
    }

    // MARK: - Sign Up (New Account)
    public func signUp(email: String, password: String, name: String?) async -> Result<UserProfile, Error> {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else {
            return .failure(NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email cannot be empty."]))
        }
        guard password.count >= 6 else {
            return .failure(NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters."]))
        }
        guard let url = URL(string: "\(baseURL)/auth/v1/signup") else {
            return .failure(NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL."]))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["email": cleanEmail, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "SupabaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network response error."]))
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = authErrorMessage(from: data, fallback: "Could not create your account.")
                return .failure(NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message]))
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure(NSError(domain: "SupabaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected response creating your account."]))
            }
            let user = (json["user"] as? [String: Any]) ?? json
            guard let userId = user["id"] as? String else {
                return .failure(NSError(domain: "SupabaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected response creating your account."]))
            }

            // If the project requires email confirmation, Supabase returns the user but no session yet.
            guard let accessToken = json["access_token"] as? String,
                  let refreshToken = json["refresh_token"] as? String else {
                return .failure(NSError(domain: "SupabaseService", code: 202, userInfo: [NSLocalizedDescriptionKey: "Check your inbox to confirm your email, then sign in."]))
            }

            storeSession(accessToken: accessToken, refreshToken: refreshToken, userId: userId)

            let profile = await createProfileRow(userId: userId, email: cleanEmail, name: name)
            return .success(profile)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Sign In (Existing Account)
    public func signIn(email: String, password: String) async -> Result<UserProfile, Error> {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty, !password.isEmpty else {
            return .failure(NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Enter your email and password."]))
        }
        guard let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password") else {
            return .failure(NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL."]))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["email": cleanEmail, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "SupabaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network response error."]))
            }
            guard (200...299).contains(httpResponse.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let refreshToken = json["refresh_token"] as? String,
                  let user = json["user"] as? [String: Any],
                  let userId = user["id"] as? String else {
                let message = authErrorMessage(from: data, fallback: "Incorrect email or password.")
                return .failure(NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message]))
            }

            storeSession(accessToken: accessToken, refreshToken: refreshToken, userId: userId)

            if let uuid = UUID(uuidString: userId), let profile = await fetchProfile(byId: uuid) {
                return .success(profile)
            }
            // Signed in but no profile row yet (e.g. row was deleted server-side) — create a fresh one.
            let profile = await createProfileRow(userId: userId, email: cleanEmail, name: nil)
            return .success(profile)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Sign In with Apple
    public func signInWithApple(identityToken: String, fullName: String?) async -> Result<UserProfile, Error> {
        guard let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=id_token") else {
            return .failure(NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL."]))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["provider": "apple", "id_token": identityToken])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let refreshToken = json["refresh_token"] as? String,
                  let user = json["user"] as? [String: Any],
                  let userId = user["id"] as? String else {
                let message = authErrorMessage(from: data, fallback: "Apple Sign In failed.")
                return .failure(NSError(domain: "SupabaseService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: message]))
            }

            storeSession(accessToken: accessToken, refreshToken: refreshToken, userId: userId)
            let email = (user["email"] as? String) ?? ""

            if let uuid = UUID(uuidString: userId), let existing = await fetchProfile(byId: uuid) {
                return .success(existing)
            }
            let profile = await createProfileRow(userId: userId, email: email, name: fullName)
            return .success(profile)
        } catch {
            return .failure(error)
        }
    }

    /// Creates the public profile row for a just-authenticated user. No password is ever stored here —
    /// Supabase Auth already owns credential storage.
    private func createProfileRow(userId: String, email: String, name: String?) async -> UserProfile {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let nowISO = Self.isoFormatterStandard.string(from: Date())

        let body: [String: Any] = [
            "id": userId,
            "name": trimmedName,
            "email": email,
            "left_eye_power": 0.0,
            "right_eye_power": 0.0,
            "previous_conditions": [] as [String],
            "screen_time_hours": "6 hrs",
            "screen_time_numeric": 6.0,
            "device_activity_actual_hours": 0.0,
            "primary_activity": "General / Multitasking",
            "peak_fatigue_time": "Evening (after 7 PM)",
            "plan_summary": [
                "recommended_exercises": [] as [String],
                "baseline_rest_score": 70
            ],
            "created_at": nowISO,
            "updated_at": nowISO
        ]

        let fallbackProfile = UserProfile(
            id: UUID(uuidString: userId) ?? UUID(),
            name: trimmedName,
            email: email
        )

        guard let url = URL(string: "\(baseURL)/rest/v1/users?on_conflict=id") else {
            saveLocalProfile(fallbackProfile)
            return fallbackProfile
        }

        var request = authorizedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let record = json.first {
                let profile = parseProfileRecord(record)
                saveLocalProfile(profile)
                return profile
            }
        } catch {
            print("[SupabaseService] createProfileRow error: \(error)")
        }

        saveLocalProfile(fallbackProfile)
        return fallbackProfile
    }

    // MARK: - Upsert Profile
    @discardableResult
    public func upsertProfile(_ profile: UserProfile) async -> Bool {
        let cleanEmail = profile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let hasEmail = !cleanEmail.isEmpty

        let urlString = hasEmail
            ? "\(baseURL)/rest/v1/users?on_conflict=email"
            : "\(baseURL)/rest/v1/users?on_conflict=id"

        guard let url = URL(string: urlString) else { return false }

        var request = authorizedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")

        var body: [String: Any] = [
            "id": profile.id.uuidString,
            "name": profile.name,
            "left_eye_power": profile.leftEyePower,
            "right_eye_power": profile.rightEyePower,
            "previous_conditions": profile.previousConditions,
            "screen_time_hours": "\(Int(profile.estimatedDailyScreenTimeHours)) hrs",
            "screen_time_numeric": profile.estimatedDailyScreenTimeHours,
            "device_activity_actual_hours": profile.actualDailyScreenTimeHours ?? 0.0,
            "primary_activity": profile.primaryActivity,
            "peak_fatigue_time": profile.peakFatigueTime,
            "plan_summary": [
                "recommended_exercises": profile.recommendedExerciseIds,
                "baseline_rest_score": profile.baselineRestScore
            ],
            "updated_at": Self.isoFormatterStandard.string(from: Date())
        ]

        if hasEmail {
            body["email"] = cleanEmail
        } else {
            body["email"] = NSNull() // Essential: prevents Postgres duplicate empty string constraint error
        }

        // Cache on device immediately
        saveLocalProfile(profile)

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("[SupabaseService] Successfully synced profile to Supabase")
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let record = json.first {
                    let updatedProfile = parseProfileRecord(record)
                    saveLocalProfile(updatedProfile)
                }
                return true
            } else {
                let errString = String(data: data, encoding: .utf8) ?? "Unknown"
                print("[SupabaseService] Upsert failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1), error: \(errString)")
                return false
            }
        } catch {
            print("[SupabaseService] Network upsert error: \(error). Saved locally.")
            return false
        }
    }

    // MARK: - Fetch Profile by Email
    public func fetchProfile(byEmail email: String) async -> UserProfile? {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty,
              let encodedEmail = cleanEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/rest/v1/users?email=eq.\(encodedEmail)&select=*") else {
            return nil
        }

        let request = authorizedRequest(url: url, method: "GET")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let record = json.first else {
                return nil
            }

            let profile = parseProfileRecord(record)
            saveLocalProfile(profile)
            return profile
        } catch {
            print("[SupabaseService] fetchProfile error: \(error)")
            return nil
        }
    }

    // MARK: - Fetch Profile by ID
    public func fetchProfile(byId id: UUID) async -> UserProfile? {
        guard let url = URL(string: "\(baseURL)/rest/v1/users?id=eq.\(id.uuidString)&select=*") else {
            return nil
        }

        let request = authorizedRequest(url: url, method: "GET")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let record = json.first else {
                return nil
            }

            let profile = parseProfileRecord(record)
            saveLocalProfile(profile)
            return profile
        } catch {
            print("[SupabaseService] fetchProfile byId error: \(error)")
            return nil
        }
    }

    // MARK: - Synchronize Profile with Remote
    @discardableResult
    public func syncProfileWithRemote() async -> UserProfile? {
        await refreshSessionIfNeeded()

        guard let local = currentProfile ?? loadLocalProfile() else {
            return nil
        }

        let cleanEmail = local.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !cleanEmail.isEmpty {
            if let remote = await fetchProfile(byEmail: cleanEmail) {
                if remote.updatedAt > local.updatedAt {
                    print("[SupabaseService] Remote profile is newer, updating device cache.")
                    saveLocalProfile(remote)
                    return remote
                } else if local.updatedAt > remote.updatedAt {
                    print("[SupabaseService] Device profile is newer, updating Supabase.")
                    _ = await upsertProfile(local)
                    return local
                } else {
                    saveLocalProfile(remote)
                    return remote
                }
            } else {
                // If user doesn't exist remotely yet, upload current local profile
                print("[SupabaseService] User not yet in Supabase, creating remote record.")
                _ = await upsertProfile(local)
                return local
            }
        } else {
            // Guest user
            if let remote = await fetchProfile(byId: local.id) {
                saveLocalProfile(remote)
                return remote
            } else {
                _ = await upsertProfile(local)
                return local
            }
        }
    }

    // MARK: - Local Storage & Device Caching
    public func saveLocalProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: localProfileKey)
            if !profile.email.isEmpty {
                UserDefaults.standard.set(profile.email, forKey: localEmailKey)
            }
            UserDefaults.standard.set(profile.id.uuidString, forKey: localUserIdKey)
            UserDefaults.standard.synchronize()
        }
        self.currentProfile = profile
    }

    public func loadLocalProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: localProfileKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return profile
    }

    // MARK: - Logout
    public func logout() {
        self.currentProfile = nil
        clearSession()
        UserDefaults.standard.removeObject(forKey: localProfileKey)
        UserDefaults.standard.removeObject(forKey: localEmailKey)
        UserDefaults.standard.removeObject(forKey: localUserIdKey)
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "lucid_exercises_completed")
        UserDefaults.standard.removeObject(forKey: "lucid_day_streak")
        UserDefaults.standard.removeObject(forKey: "lucid_last_exercise_date")
        UserDefaults.standard.synchronize()
        print("[SupabaseService] User successfully logged out and local session cleared.")
    }
}

// MARK: - Minimal Keychain wrapper for auth tokens

private enum Keychain {
    static func save(_ key: String, _ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func load(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
