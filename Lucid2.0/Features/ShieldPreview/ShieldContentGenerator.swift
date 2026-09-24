import Foundation
import ManagedSettings

public struct ShieldContent {
    public let title: String
    public let subtitle: String
    public let appName: String
}

public class ShieldContentGenerator {
    
    public static let shared = ShieldContentGenerator()
    
    private let genericQuotes = [
        "Time to reclaim your focus! 🚀",
        "Your future self will thank you. 🌱",
        "Disconnect to reconnect with your goals. ⚡️",
        "Great things come from deep work. 🧠",
        "Break the cycle, find your flow. 🌊",
        "Less scrolling, more living. ✨",
        "You're in control of your time. 👑",
        "Step away and breathe. 🌬️",
        "Protect your peace and focus. 🛡️",
        "Invest this time in yourself. 📈"
    ]
    
    private let socialQuotes = [
        "Real life is happening right now. 🌍",
        "Stop comparing, start creating. 🎨",
        "Disconnect from the feed, connect with yourself. 🧘",
        "Your self-worth isn't measured in likes. 💖",
        "Take a break from the noise. 🤫"
    ]
    
    private let gamesQuotes = [
        "Level up in real life instead! 🏆",
        "Pause the game, resume your goals. 🎯",
        "The best quests are outside. 🗺️",
        "Save your high score for later. 💾"
    ]
    
    private let entertainmentQuotes = [
        "Be the star of your own life. 🎬",
        "Time for an intermission. 🍿",
        "Create more than you consume. ✍️",
        "The screen can wait. You can't. ⏳"
    ]
    
    public func generateContent(appName: String?, categoryName: String?) -> ShieldContent {
        let name = appName ?? "This app"
        let title = "🛑 Blocked: \(name)"
        
        var quotesPool = genericQuotes
        
        if let cat = categoryName?.lowercased() {
            if cat.contains("social") {
                quotesPool += socialQuotes
            } else if cat.contains("game") {
                quotesPool += gamesQuotes
            } else if cat.contains("entertain") || cat.contains("video") {
                quotesPool += entertainmentQuotes
            }
        }
        
        let randomQuote = quotesPool.randomElement() ?? genericQuotes[0]
        
        // 3 lines consolidated:
        // Line 1: (Title handles this) 🛑 Blocked: [App Name]
        // Line 2: The motivational quote with emoji
        // Line 3: Why we are blocking it
        let reason = "It's restricted by your focus schedule."
        
        let subtitle = "\(randomQuote)\n\(reason)"
        
        return ShieldContent(title: title, subtitle: subtitle, appName: name)
    }
}
