import SwiftUI

struct PhoneInputView: View {
    @State private var phone: String = ""
    @State private var showError: Bool = false
    @State private var isChecking: Bool = false
    @State private var nextScreen: Bool = false
    @State private var isUserExists: Bool? = nil
    @State private var userName: String = ""
    @State private var digitsOnly: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Введите номер телефона")
                        .font(.title2)
                        .bold()
                    
                    TextField("+7 (XXX) XXX-XX-XX", text: $phone)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .onChange(of: phone) { newValue in
                            digitsOnly = newValue.filter("0123456789".contains)
                            
                            if digitsOnly.hasPrefix("7") {
                                digitsOnly = String(digitsOnly.dropFirst())
                            }
                            if digitsOnly.count > 10 {
                                digitsOnly = String(digitsOnly.prefix(10))
                            }
                            
                            var formatted = "+7"
                            if digitsOnly.count > 0 {
                                formatted += " (" + String(digitsOnly.prefix(3))
                            }
                            if digitsOnly.count > 3 {
                                formatted += ") " + String(digitsOnly.dropFirst(3).prefix(3))
                            }
                            if digitsOnly.count > 6 {
                                formatted += "-" + String(digitsOnly.dropFirst(6).prefix(2))
                            }
                            if digitsOnly.count > 8 {
                                formatted += "-" + String(digitsOnly.dropFirst(8))
                            }
                            
                            phone = formatted
                            showError = false
                        }
                    
                    Text("Осталось ввести: \(10 - digitsOnly.count) цифр")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    if showError {
                        Text("Введите корректный номер")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    Button(action: {
                        if digitsOnly.count < 10 {
                            showError = true
                            return
                        }
                        
                        isChecking = true
                        
                        guard let url = URL(string: "http://localhost:3001/check-user") else { return }
                        
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        let body = ["phone": phone]
                        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                        
                        URLSession.shared.dataTask(with: request) { data, response, error in
                            defer { isChecking = false }
                            
                            guard let data = data,
                                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                                DispatchQueue.main.async {
                                    isUserExists = false
                                    nextScreen = true
                                }
                                return
                            }
                            
                            DispatchQueue.main.async {
                                if let exists = json["exists"] as? Bool {
                                    isUserExists = exists
                                    if exists, let name = json["name"] as? String {
                                        userName = name
                                    }
                                } else {
                                    isUserExists = false
                                }
                                nextScreen = true
                            }
                        }.resume()
                        
                    }) {
                        if isChecking {
                            ProgressView()
                        } else {
                            Text("Продолжить")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    NavigationLink(destination: PasswordInputView(userName: userName, isLogin: true, phone: phone), isActive: Binding(
                        get: { nextScreen && isUserExists == true },
                        set: { _ in }
                    )) {
                        EmptyView()
                    }
                    
                    NavigationLink(destination: NameInputView(phone: phone), isActive: Binding(
                        get: { nextScreen && isUserExists == false },
                        set: { _ in }
                    )) {
                        EmptyView()
                    }
                }
                .padding()
                .frame(maxWidth: 400)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
