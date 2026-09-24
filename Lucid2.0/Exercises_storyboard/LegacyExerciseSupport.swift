//
//  LegacyExerciseSupport.swift
//  Lucid2.0
//
//  Provides data models, JSON persistence, and UIKit extensions
//  required by the storyboard-backed eye exercises.
//

import UIKit

// MARK: - Notification Names
extension Notification.Name {
    public static let legacyExerciseDidComplete = Notification.Name("legacyExerciseDidComplete")
}

// MARK: - Color Extension for Legacy UI
extension UIColor {
    public static var accent: UIColor {
        UIColor(named: "AccentColor") ?? UIColor(red: 52/255, green: 211/255, blue: 153/255, alpha: 1.0)
    }
}

// MARK: - Instruction Tracker
public struct InstructionTracker {
    public static var firstRunStatus: [String: Int] = {
        var status: [String: Int] = [:]
        let keys = ["PencilPushup", "SaccadicJumps", "SmoothPursuits", "PeripheralAwareness", "Figure8", "NearFar", "Blink", "CTest", "OSDI"]
        for key in keys {
            if let savedValue = UserDefaults.standard.object(forKey: "InstructionFirstRun_\(key)") as? Int {
                status[key] = savedValue
            } else {
                status[key] = 1 // Default to 1 (first run)
            }
        }
        return status
    }()
    
    public static func isFirstRun(for exerciseKey: String) -> Bool {
        return (firstRunStatus[exerciseKey] ?? 1) == 1
    }
    
    public static func markAsCompleted(for exerciseKey: String) {
        firstRunStatus[exerciseKey] = 0
        UserDefaults.standard.set(0, forKey: "InstructionFirstRun_\(exerciseKey)")
    }
}

// MARK: - Streak Day
public struct StreakDay: Codable {
    public var date: Date
    public var isCompleted: Bool
    
    public init(date: Date, isCompleted: Bool) {
        self.date = date
        self.isCompleted = isCompleted
    }
}

// MARK: - User
public final class User: Codable {
    public var id: UUID
    public var name: String
    public var age: Int
    public var email: String?
    public var password: String?
    public var dateOfBirth: Date?
    public var gender: String?
    public var leftEyePower: Double
    public var rightEyePower: Double
    public var createdAt: Date
    public var dailyExerciseGoal: Int 
    public var recommendedExercises: [String] = []
    public var previousConditions: [String] = []
    private var streakData: [StreakDay]?
    
    public var streak: [StreakDay] {
        get { streakData ?? [] }
        set { streakData = newValue }
    }
    
    public init(name: String, age: Int, dailyGoal: Int = 150) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.email = nil
        self.password = nil
        self.dateOfBirth = nil
        self.gender = nil
        self.leftEyePower = 0
        self.rightEyePower = 0
        self.createdAt = Date()
        self.dailyExerciseGoal = dailyGoal
        self.streakData = []
    }

    public var exerciseSessions: [ExerciseSession] {
        SwiftDataManager.shared.fetchExerciseSessions()
    }

    public func calculateDailyGoalFromRecommendations() -> Int {
        let exerciseTimes: [String: Int] = [
            "SmoothPursuit": 135,
            "SaccadicJump": 70,
            "PencilPushup": 60,
            "Figure8": 90,
            "Blink": 90,
            "NearFar": 110
        ]
        let currentRecs = recommendedExercises.isEmpty ? ["SmoothPursuit", "Blink"] : recommendedExercises
        let sum = currentRecs.compactMap { exerciseTimes[$0] }.reduce(0, +)
        let minutes = Int(ceil(Double(sum) / 60.0))
        return minutes * 60
    }

    public func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if streakData == nil {
            streakData = []
        }
        
        if !streak.contains(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            self.dailyExerciseGoal = calculateDailyGoalFromRecommendations()
            
            let completedSeconds = getTotalSeconds(for: today)
            let isCompleted = (completedSeconds / 60) >= (dailyExerciseGoal / 60)
            self.streak.append(StreakDay(date: today, isCompleted: isCompleted))
            self.streak.sort(by: { $0.date < $1.date })
            try? SwiftDataManager.shared.context.save()
        }
    }

    public func updateTodayStreakStatus() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        checkDailyReset()
        
        let completedSeconds = getTotalSeconds(for: today)
        let isCompleted = (completedSeconds / 60) >= (dailyExerciseGoal / 60)
        
        if let index = streak.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            streak[index].isCompleted = isCompleted
        } else {
            streak.append(StreakDay(date: today, isCompleted: isCompleted))
        }
        
        try? SwiftDataManager.shared.context.save()
    }

    public func getTotalSeconds(for date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let dailySessions = exerciseSessions.filter {
            $0.startingDate >= start && $0.startingDate < end
        }
        return dailySessions.reduce(0) { $0 + $1.durationSeconds }
    }
}

// MARK: - ExerciseSession
public final class ExerciseSession: Codable {
    public var id: UUID
    public var startingDate: Date
    public var startingTime: Date
    public var endingTime: Date
    public var type: String // "Blink", "PencilPushup", "SmoothPursuit", "Figure8", "NearFar", "SaccadicJumps", "PeripheralAwareness"
    public var durationSeconds: Int
    
    public var accuracyScore: Int?
    public var averageBlinkIntensity: Float?
    public var errorCount: Int?
    public var headMovementDegrees: Float?
    public var directionErrors: [String: Double]?
    public var errorsPerSession: [Int]?
    public var nearPointOfConvergence: Float?
    public var paceScore: Double?
    public var rightEyeBlinks: Int?
    public var leftEyeBlinks: Int?
    public var responsivenessScore: Double?
    
    public var user: User? {
        get { SwiftDataManager.shared.getOrCreateUser() }
        set { }
    }

    public init(type: String, duration: Int, accuracy: Int? = nil, intensity: Float? = nil, errors: Int? = 0) {
        self.id = UUID()
        self.startingDate = Date()
        self.startingTime = Date()
        self.endingTime = Date()
        self.type = type
        self.durationSeconds = duration
        self.accuracyScore = accuracy
        self.averageBlinkIntensity = intensity
        self.errorCount = errors
    }
}

// MARK: - Local Database Representation
public struct LocalDatabase: Codable {
    public var user: User
    public var exerciseSessions: [ExerciseSession] = []
    
    public init(user: User, exerciseSessions: [ExerciseSession] = []) {
        self.user = user
        self.exerciseSessions = exerciseSessions
    }
}

// MARK: - SwiftDataManager
@MainActor
public final class SwiftDataManager {
    public static let shared = SwiftDataManager()
    
    private let fileURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("local_database.json")
    }()
    
    private var cachedDatabase: LocalDatabase?
    
    public var context: SwiftDataManager { self }
    
    private init() {
        loadDatabase()
    }
    
    private func loadDatabase() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let defaultUser = User(name: "User", age: 25)
            self.cachedDatabase = LocalDatabase(user: defaultUser)
            saveInternal()
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let db = try decoder.decode(LocalDatabase.self, from: data)
            self.cachedDatabase = db
        } catch {
            print("Failed to load local JSON database: \(error)")
            let defaultUser = User(name: "User", age: 25)
            self.cachedDatabase = LocalDatabase(user: defaultUser)
            saveInternal()
        }
    }
    
    private func saveInternal() {
        guard let db = cachedDatabase else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(db)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save local JSON database: \(error)")
        }
    }
    
    public func save() throws {
        saveInternal()
    }
    
    public func getOrCreateUser() -> User {
        if let user = cachedDatabase?.user {
            return user
        }
        let newUser = User(name: "User", age: 25)
        cachedDatabase = LocalDatabase(user: newUser)
        saveInternal()
        return newUser
    }
    
    public func insert(_ session: ExerciseSession) {
        if cachedDatabase == nil {
            _ = getOrCreateUser()
        }
        cachedDatabase?.exerciseSessions.append(session)
        saveInternal()
        
        UserDefaults.standard.set(true, forKey: "summary.dailyExercises.lastLaunchSuccess")
        
        let user = getOrCreateUser()
        user.updateTodayStreakStatus()
    }
    
    public func fetchExerciseSessions() -> [ExerciseSession] {
        return cachedDatabase?.exerciseSessions ?? []
    }
}
