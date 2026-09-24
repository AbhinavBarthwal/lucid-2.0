import SwiftUI
import ManagedSettings

public struct ShieldPreviewView: View {
    let appName: String
    let categoryName: String?
    
    @State private var content: ShieldContent?
    
    public init(appName: String = "Instagram", categoryName: String? = "Social") {
        self.appName = appName
        self.categoryName = categoryName
    }
    
    public var body: some View {
        ZStack {
            // Gradient Background requested by user
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Shield Icon (Simulating Apple's shield icon or a custom one)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.white, .white.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 100, height: 100)
                        .shadow(radius: 10)
                    
                    Image(systemName: "hourglass.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.indigo)
                }
                .padding(.top, 60)
                
                if let content = content {
                    VStack(spacing: 16) {
                        // Line 1: Title
                        Text(content.title)
                            .font(Typography.hero(size: 28, weight: .bold, design: .rounded, relativeTo: .title))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Line 2 & 3: Subtitle (Quote + Reason)
                        Text(content.subtitle)
                            .font(Typography.body(weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 32)
                    }
                } else {
                    ProgressView()
                        .tint(.white)
                }
                
                Spacer()
                
                // Primary Action Button (Simulating 'OK' or 'Close')
                Button(action: {
                    // Simulating a button press
                }) {
                    Text("Got it")
                        .font(Typography.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .glassEffect(.clear, in: .capsule)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            self.content = ShieldContentGenerator.shared.generateContent(appName: appName, categoryName: categoryName)
        }
    }
}

#Preview {
    ShieldPreviewView(appName: "TikTok", categoryName: "Social")
}
