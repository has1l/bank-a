

import SwiftUI

struct NameInputView: View {
    let phone: String
    @State private var name: String = ""
    @State private var nextStep: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Как вас зовут?")
                .font(.title2)
                .bold()

            TextField("Ваше имя", text: $name)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)

            Button("Продолжить") {
                if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                    nextStep = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            NavigationLink(destination: PasswordInputView(userName: name, isLogin: false, phone: phone), isActive: $nextStep) {
                EmptyView()
            }
        }
        .padding()
        .frame(maxWidth: 400)
        .navigationTitle("Регистрация")
        .navigationBarBackButtonHidden(true)
    }
}