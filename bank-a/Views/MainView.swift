import SwiftUI
import PhotosUI

struct SoftGradientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.pink.opacity(0.4),
                    Color.purple.opacity(0.4),
                    Color.orange.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: 40)

            Circle()
                .fill(Color.pink.opacity(0.5))
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -150)

            Circle()
                .fill(Color.purple.opacity(0.5))
                .frame(width: 400, height: 400)
                .offset(x: 100, y: 200)

            Circle()
                .fill(Color.orange.opacity(0.5))
                .frame(width: 300, height: 300)
                .offset(x: 150, y: -200)
        }
    }
}

struct MainView: View {
    let userName: String
    let userPhone: String
    @AppStorage("savedPhone") var savedPhone: String?

    var body: some View {
        TabBarView(userName: userName, phone: userPhone)
            .onAppear {
                savedPhone = userPhone
            }
    }
}

struct HomeTab: View {
    @State private var showProfileSheet = false
    @State private var image: UIImage? = UIImage(systemName: "person.circle.fill")
    @State private var selectedItem: PhotosPickerItem?
    @AppStorage("savedPhone") var savedPhone: String?
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToProfile = false

    @State private var balance: String = "..."
    @State private var showBalanceEditor = false
    @State private var newBalanceInput = ""

    let userName: String

    var body: some View {
        ZStack {
            SoftGradientBackground()
            NavigationView {
                ZStack {
                    VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button(action: {
                            navigateToProfile = true
                        }) {
                            if let image = image {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding([.trailing, .top])

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.gray)
                            Text("Black")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }

                        HStack {
                            Text("\(balance)")
                                .font(.system(size: 28, weight: .bold, design: .default))
                            Text("₽")
                                .font(.system(size: 22, weight: .medium))
                                .padding(.leading, -4)

                            Spacer()

                            Button("Изменить") {
                                newBalanceInput = ""
                                showBalanceEditor = true
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, -6)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white.opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.3), value: balance)

                    Spacer()

                    Text("Привет, \(userName) 👋")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .padding(.top, 32)

                    Spacer()
                    
                        NavigationLink(destination: ProfileView(userName: userName), isActive: $navigateToProfile) {
                            EmptyView()
                        }
                    }
                }
            }
            .background(Color.clear)
            .navigationBarHidden(true)
            .onAppear {
                if let phone = savedPhone {
                    let cleanPhone = phone.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
                    guard let url = URL(string: "http://localhost:3001/balance?phone=\(cleanPhone)") else { return }
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data {
                            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                if let balanceString = json["balance"] as? String,
                                   let doubleValue = Double(balanceString) {
                                    DispatchQueue.main.async {
                                        balance = String(format: "%.2f", doubleValue)
                                    }
                                }
                            }
                        }
                    }.resume()
                }
            }
            .alert("Изменить баланс", isPresented: $showBalanceEditor, actions: {
                TextField("Новый баланс", text: $newBalanceInput)
                    .keyboardType(.decimalPad)
                Button("Сохранить") {
                    if let phone = savedPhone,
                       let url = URL(string: "http://localhost:3001/balance"),
                       let balanceValue = Double(newBalanceInput) {
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        let payload: [String: Any] = ["phone": phone.replacingOccurrences(of: "\\D", with: "", options: .regularExpression), "balance": balanceValue]
                        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

                        URLSession.shared.dataTask(with: request) { _, _, _ in
                            DispatchQueue.main.async {
                                balance = String(format: "%.2f", balanceValue)
                            }
                        }.resume()
                    }
                }
                Button("Отмена", role: .cancel) { }
            }, message: {
                Text("Введите новый баланс в рублях")
            })
        }
    }
} 
