import SwiftUI
import Foundation

struct TabBarView: View {
    let userName: String
    let phone: String

    var body: some View {
        ZStack {
            TabView {
                HomeTab(userName: userName)
                    .tabItem {
                        Label("Главная", systemImage: "house")
                    }

                ExpensesTab(userPhone: phone)
                    .tabItem {
                        Label("Траты", systemImage: "chart.pie.fill")
                    }

                BoostView()
                    .tabItem {
                        Label("Буст", systemImage: "bolt.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Настройки", systemImage: "gearshape.fill")
                    }
            }
            .background(Color.black.opacity(0.85).ignoresSafeArea(edges: .bottom))
        }
    }
}