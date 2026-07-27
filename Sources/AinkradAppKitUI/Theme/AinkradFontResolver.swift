import SwiftUI
import AinkradAppKitContract

/// Maps a type role to a Font, honoring an optional brand family + user scale.
/// Defaults to the system font when no family is injected (plugins without the
/// host's registered brand faces still render legibly).
public enum AinkradFontResolver {
    public static func pointSize(_ role: AinkradTypeRole, typography: AinkradTypography) -> CGFloat {
        role.size * typography.scale
    }
    public static func font(_ role: AinkradTypeRole, weight: Font.Weight = .regular,
                            typography: AinkradTypography) -> Font {
        let size = pointSize(role, typography: typography)
        if role == .mono {
            return .custom("JetBrains Mono", size: size).weight(weight)
        }
        if let family = typography.fontFamilyName {
            return .custom(family, size: size).weight(weight)
        }
        return .system(size: size).weight(weight)
    }
}
