import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("primaryColor") var primaryColorHex: String = "#3E5F8A"
    @AppStorage("accentColor") var accentColorHex: String = "#FFD700"
    @AppStorage("textColor") var textColorHex: String = "#000000"
    
    var primaryColor: Color { Color(hex: primaryColorHex) }
    var accentColor: Color { Color(hex: accentColorHex) }
    var textColor: Color { Color(hex: textColorHex) }
}

struct SettingsView: View {
    @StateObject private var theme = ThemeManager()
    @AppStorage("primaryColor") private var primaryColorHex: String = "#3E5F8A"
    @AppStorage("accentColor") private var accentColorHex: String = "#FFD700"
    @AppStorage("textColor") private var textColorHex: String = "#000000"
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("Настройки")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

#Preview {
    SettingsView().environmentObject(ThemeManager())
}