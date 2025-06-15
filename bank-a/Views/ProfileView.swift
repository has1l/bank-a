import SwiftUI

struct ProfileView: View {
    @AppStorage("savedPhone") var savedPhone: String?
    @State private var image: UIImage? = UIImage(systemName: "person.circle.fill")
    @Environment(\.presentationMode) var presentationMode

    var userName: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                        .foregroundColor(.blue)
                        .font(.body)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "camera")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }

                    Text(userName)
                        .font(.title2)
                        .bold()

                    Text(savedPhone ?? "")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                VStack(spacing: 16) {
                    ForEach(["Ваши данные", "Безопасность", "Настройки"], id: \.self) { title in
                        HStack {
                            Text(title)
                                .font(.body)
                                .padding()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }

                Button("Выйти из аккаунта") {
                    savedPhone = nil
                    UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: PhoneInputView())
                }
                .foregroundColor(.red)
                .padding(.top, 32)

                Spacer()
            }
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitle("Профиль", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
    }
}
