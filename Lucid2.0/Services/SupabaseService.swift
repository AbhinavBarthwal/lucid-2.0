//
//  SupabaseService.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import Foundation
import Combine

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

    // MARK: - Check User Exists by Email
    public func checkUserExists(email: String) async -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else { return false }

        guard let encodedEmail = cleanEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/rest/v1/users?email=eq.\(encodedEmail)&select=id") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]], !json.isEmpty {
                return true
            }
            return false
        } catch {
            print("[SupabaseService] checkUserExists error: \(error)")
            return false
        }
    }

    // MARK: - Verify Password
    public func verifyPassword(email: String, password: String) async -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty, !password.isEmpty else { return false }

        guard let encodedEmail = cleanEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/rest/v1/users?email=eq.\(encodedEmail)&select=password") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let record = json.first,
               let storedPass = record["password"] as? String {
                return storedPass == password
            }
            return false
        } catch {
            print("[SupabaseService] verifyPassword error: \(error)")
            return false
        }
    }

    // MARK: - Create User (New Account Registration)
    public func createUser(
        email: String,
        password: String,
        name: String? = nil
    ) async -> Result<UserProfile, Error> {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else {
            return .failure(NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email cannot be empty."]))
        }
        guard !password.isEmpty, password.count >= 6 else {
            return .failure(NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters."]))
        }

        // Verify if user already exists
        let exists = await checkUserExists(email: cleanEmail)
        if exists {
            return .failure(NSError(domain: "SupabaseService", code: 409, userInfo: [NSLocalizedDescriptionKey: "An account with this email already exists. Please sign in instead."]))
        }

        guard let url = URL(string: "\(baseURL)/rest/v1/users?on_conflict=email") else {
            return .failure(NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL."]))
        }

        let newId = UUID()
        let nowISO = Self.isoFormatterStandard.string(from: Date())
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var body: [String: Any] = [
            "id": newId.uuidString,
            "name": trimmedName,
            "email": cleanEmail,
            "password": password,
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

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "SupabaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network response error."]))
            }

            if (200...299).contains(httpResponse.statusCode) {
                var profile: UserProfile
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let record = json.first {
                    profile = parseProfileRecord(record)
                } else if let fetched = await fetchProfile(byEmail: cleanEmail) {
                    profile = fetched
                } else {
                    profile = UserProfile(
                        id: newId,
                        name: trimmedName,
                        email: cleanEmail,
                        leftEyePower: 0.0,
                        rightEyePower: 0.0,
                        hasGlassesOrContacts: false,
                        previousConditions: [],
                        estimatedDailyScreenTimeHours: 6.0,
                        actualDailyScreenTimeHours: 0.0,
                        primaryActivity: "Coding & Reading",
                        peakFatigueTime: "Late Day (5–8)",
                        recommendedExerciseIds: [],
                        baselineRestScore: 70
                    )
                }

                // Immediately cache locally on device
                saveLocalProfile(profile)
                print("[SupabaseService] Created new user: \(profile.email), cached locally and synced.")
                return .success(profile)
            } else {
                let errString = String(data: data, encoding: .utf8) ?? "Unknown server error"
                print("[SupabaseService] Create user failed (\(httpResponse.statusCode)): \(errString)")
                return .failure(NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create user: \(errString)"]))
            }
        } catch {
            print("[SupabaseService] Network error creating user: \(error)")
            return .failure(error)
        }
    }

    // MARK: - Upsert Profile
    @discardableResult
    public func upsertProfile(_ profile: UserProfile, password: String? = nil) async -> Bool {
        let cleanEmail = profile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let hasEmail = !cleanEmail.isEmpty

        let urlString = hasEmail
            ? "\(baseURL)/rest/v1/users?on_conflict=email"
            : "\(baseURL)/rest/v1/users?on_conflict=id"

        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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

        if let password, !password.isEmpty {
            body["password"] = password
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

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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
