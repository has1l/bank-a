import SwiftUI

struct PasswordInputView: View {
    let userName: String
    @State var isLogin: Bool
    let phone: String
    @State private var password: String = ""
    @State private var isLoggedIn = false

    @State private var confirmStep = false
    @State private var confirmedPassword = ""
    @State private var showMismatch = false


    var body: some View {
        VStack(spacing: 30) {
            Text(userName)
                .font(.title)
                .bold()

            HStack(spacing: 12) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < password.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }

            if confirmStep {
                Text("Повторите пароль")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            if showMismatch {
                Text("Пароли не совпадают, попробуйте ещё раз")
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            VStack(spacing: 10) {
                ForEach(["123", "456", "789", "⌫0"], id: \.self) { row in
                    HStack(spacing: 30) {
                        ForEach(row.map { String($0) }, id: \.self) { char in
                            Button(action: {
                                if char == "⌫" {
                                    if !password.isEmpty {
                                        password.removeLast()
                                    }
                                } else if password.count < 4 {
                                    password.append(char)
                                }
                                
                                if password.count == 4 {
                                    if isLogin {
                                        let url = URL(string: "http://localhost:3001/login")!
                                        var request = URLRequest(url: url)
                                        request.httpMethod = "POST"
                                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                                        let body: [String: Any] = [
                                            "phone": phone,
                                            "password": password
                                        ]
                                        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

                                        URLSession.shared.dataTask(with: request) { data, response, error in
                                            if let httpResponse = response as? HTTPURLResponse,
                                               httpResponse.statusCode == 200 {
                                                DispatchQueue.main.async {
                                                    UserDefaults.standard.set(phone, forKey: "savedPhone")
                                                    UserDefaults.standard.set(true, forKey: "userDidLogin")
                                                    isLoggedIn = true
                                                }
                                            }
                                        }.resume()
                                    } else {
                                        if confirmStep {
                                            if password == confirmedPassword {
                                                let url = URL(string: "http://localhost:3001/register")!
                                                var request = URLRequest(url: url)
                                                request.httpMethod = "POST"
                                                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                                                let body: [String: Any] = [
                                                    "name": userName,
                                                    "phone": phone,
                                                    "password": password
                                                ]
                                                request.httpBody = try? JSONSerialization.data(withJSONObject: body)

                                                URLSession.shared.dataTask(with: request) { data, response, error in
                                                    if let httpResponse = response as? HTTPURLResponse,
                                                       (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
                                                        DispatchQueue.main.async {
                                                            UserDefaults.standard.set(phone, forKey: "savedPhone")
                                                            UserDefaults.standard.set(true, forKey: "userDidLogin")
                                                            isLoggedIn = true
                                                            confirmedPassword = ""
                                                            showMismatch = false
                                                        }
                                                    }
                                                }.resume()
                                            } else {
                                                showMismatch = true
                                                password = ""
                                                confirmStep = false
                                            }
                                        } else {
                                            confirmedPassword = password
                                            password = ""
                                            confirmStep = true
                                        }
                                    }
                                }
                            }) {
                                Text(char)
                                    .font(.title2)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .cornerRadius(30)
                                    .shadow(radius: 3)
                            }
                        }
                    }
                }
            }

            NavigationLink(destination: MainView(userName: userName, userPhone: phone).navigationBarBackButtonHidden(true), isActive: $isLoggedIn) {
                EmptyView()
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}