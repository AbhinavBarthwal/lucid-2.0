import ManagedSettings
import ManagedSettingsUI
import UIKit

// Make sure to add `ShieldContentGenerator.swift` to this target's Build Phases -> Compile Sources!

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    // Note: Apple doesn't allow full custom SwiftUI gradients for the *background* of the shield directly via ShieldConfiguration.
    // You can only set a solid backgroundColor.
    // However, we can generate our 3-line quotes and set them as title and subtitle.
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Here we have access to the localizedDisplayName of the application!
        let appName = application.localizedDisplayName ?? "this app"
        
        let content = ShieldContentGenerator.shared.generateContent(appName: appName, categoryName: nil)
        return buildShield(from: content)
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let appName = application.localizedDisplayName ?? "this app"
        let categoryName = category.localizedDisplayName
        
        let content = ShieldContentGenerator.shared.generateContent(appName: appName, categoryName: categoryName)
        return buildShield(from: content)
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let name = webDomain.domain ?? "this website"
        let content = ShieldContentGenerator.shared.generateContent(appName: name, categoryName: nil)
        return buildShield(from: content)
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        let name = webDomain.domain ?? "this website"
        let categoryName = category.localizedDisplayName
        let content = ShieldContentGenerator.shared.generateContent(appName: name, categoryName: categoryName)
        return buildShield(from: content)
    }
    
    // Fallback for just a category
    override func configuration(shielding activityCategory: ActivityCategory) -> ShieldConfiguration {
        let categoryName = activityCategory.localizedDisplayName ?? "this category"
        let content = ShieldContentGenerator.shared.generateContent(appName: "apps in \(categoryName)", categoryName: categoryName)
        return buildShield(from: content)
    }
    
    private func buildShield(from content: ShieldContent) -> ShieldConfiguration {
        // Since we can't do a gradient background directly, we use a dark blur and a custom colored icon.
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.systemIndigo.withAlphaComponent(0.2), // Subtle tint
            icon: UIImage(systemName: "hourglass.circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: content.title, color: .white),
            subtitle: ShieldConfiguration.Label(text: content.subtitle, color: .lightText),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Got it", color: .white),
            primaryButtonBackgroundColor: UIColor.systemPurple
        )
    }
}
