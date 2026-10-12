import SwiftUI

public enum AppTheme {
    /// NAVY - PMS 281 C: Primary headers, navigation titles, prominent buttons
    public static let navy = Color(red: 0.0 / 255.0, green: 32.0 / 255.0, blue: 91.0 / 255.0) // #00205B
    
    /// LIGHT BLUE - PMS 298 C: Active icons, countdown timer badges, highlights, selection rings
    public static let lightBlue = Color(red: 19.0 / 255.0, green: 181.0 / 255.0, blue: 234.0 / 255.0) // #13B5EA
    
    /// GOLD - PMS 876 Metallic: Accents, warning badges, card borders, study status
    public static let gold = Color(red: 139.0 / 255.0, green: 99.0 / 255.0, blue: 75.0 / 255.0) // #8B634B
    
    /// WHITE: Card backgrounds, dark button labels, pure contrasts
    public static let pureWhite = Color.white // #FFFFFF
    
    /// Background Canvas Color
    public static let canvasBackground = Color(UIColor.systemGroupedBackground)
}
