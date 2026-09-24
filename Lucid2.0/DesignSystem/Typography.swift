//
//  Typography.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI
import UIKit

public enum Typography {
    /// Dynamic display/hero size that scales relative to an Apple text style
    public static func hero(
        size: CGFloat = 64,
        weight: Font.Weight = .bold,
        design: Font.Design = .rounded,
        relativeTo textStyle: Font.TextStyle = .largeTitle
    ) -> Font {
        let uiStyle: UIFont.TextStyle = {
            switch textStyle {
            case .largeTitle: return .largeTitle
            case .title: return .title1
            case .title2: return .title2
            case .title3: return .title3
            case .headline: return .headline
            case .subheadline: return .subheadline
            case .body: return .body
            case .callout: return .callout
            case .footnote: return .footnote
            case .caption: return .caption1
            case .caption2: return .caption2
            @unknown default: return .largeTitle
            }
        }()
        let scaledSize = UIFontMetrics(forTextStyle: uiStyle).scaledValue(for: size)
        return .system(size: scaledSize, weight: weight, design: design)
    }

    /// Large display title (34pt base, scales dynamically with .largeTitle)
    public static func largeTitle(weight: Font.Weight = .bold, design: Font.Design = .default) -> Font {
        .system(.largeTitle, design: design).weight(weight)
    }

    /// Primary titles (28pt base, scales dynamically with .title)
    public static func title(weight: Font.Weight = .bold, design: Font.Design = .default) -> Font {
        .system(.title, design: design).weight(weight)
    }

    /// Section titles (22pt base, scales dynamically with .title2)
    public static func title2(weight: Font.Weight = .bold, design: Font.Design = .default) -> Font {
        .system(.title2, design: design).weight(weight)
    }

    /// Card headings (20pt base, scales dynamically with .title3)
    public static func title3(weight: Font.Weight = .semibold, design: Font.Design = .default) -> Font {
        .system(.title3, design: design).weight(weight)
    }

    /// Prominent headers & buttons (17pt base, scales dynamically with .headline)
    public static func headline(weight: Font.Weight = .semibold, design: Font.Design = .default) -> Font {
        .system(.headline, design: design).weight(weight)
    }

    /// Standard body text (17pt base, scales dynamically with .body)
    public static func body(weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(.body, design: design).weight(weight)
    }

    /// Callouts and button text (16pt base, scales dynamically with .callout)
    public static func callout(weight: Font.Weight = .medium, design: Font.Design = .default) -> Font {
        .system(.callout, design: design).weight(weight)
    }

    /// Secondary descriptions (15pt base, scales dynamically with .subheadline)
    public static func subheadline(weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(.subheadline, design: design).weight(weight)
    }

    /// Detail tags & timestamps (13pt base, scales dynamically with .footnote)
    public static func footnote(weight: Font.Weight = .medium, design: Font.Design = .default) -> Font {
        .system(.footnote, design: design).weight(weight)
    }

    /// Captions & chips (12pt base, scales dynamically with .caption)
    public static func caption(weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(.caption, design: design).weight(weight)
    }

    /// Small badges & micro-copy (11pt base, scales dynamically with .caption2)
    public static func caption2(weight: Font.Weight = .bold, design: Font.Design = .default) -> Font {
        .system(.caption2, design: design).weight(weight)
    }
}

extension Font {
    /// Convenience helper for dynamic system typography with design and weight
    public static func dynamic(
        _ style: TextStyle,
        design: Design = .default,
        weight: Weight = .regular
    ) -> Font {
        .system(style, design: design).weight(weight)
    }

    /// Convenience helper for dynamic hero/display metrics
    public static func hero(
        size: CGFloat = 64,
        weight: Weight = .bold,
        design: Design = .rounded,
        relativeTo textStyle: TextStyle = .largeTitle
    ) -> Font {
        Typography.hero(size: size, weight: weight, design: design, relativeTo: textStyle)
    }
}
