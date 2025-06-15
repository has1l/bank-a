import SwiftUI

struct ProfilereelsView: View {
    @State private var selectedTab = 0
    @State private var wornGifts: Set<Int> = []
    @State private var showingGiftMenu: Bool = false
    @State private var selectedGiftIndex: Int?

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
                VStack(alignment: .leading) {
                    Text("@username")
                        .font(.title3)
                        .bold()
                    Text("Поколение Z")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()

            HStack {
                Spacer()
                VStack {
                    Text("120")
                        .bold()
                    Text("Подписки")
                        .font(.caption)
                }
                Spacer()
                VStack {
                    Text("3.5K")
                        .bold()
                    Text("Подписчики")
                        .font(.caption)
                }
                Spacer()
                VStack {
                    Text("18.2K")
                        .bold()
                    Text("Лайки")
                        .font(.caption)
                }
                Spacer()
            }
            .padding(.vertical)

            Button(action: {
            }) {
                Text("Редактировать профиль")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            Picker("", selection: $selectedTab) {
                Text("Бусты").tag(0)
                Text("Подарки").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            TabView(selection: $selectedTab) {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(0..<12) { index in
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 120)
                                .overlay(
                                    Text("Буст \(index + 1)")
                                        .font(.caption)
                                )
                        }
                    }
                    .padding()
                }
                .tag(0)

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(0..<9) { index in
                            VStack {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "gift.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 60)
                                        .foregroundColor(.pink)
                                    if wornGifts.contains(index) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .offset(x: 5, y: -5)
                                    }
                                }
                                Text("Подарок \(index + 1)")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .onTapGesture {
                                selectedGiftIndex = index
                                showingGiftMenu = true
                            }
                        }
                    }
                    .padding()
                }
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Подарок", isPresented: $showingGiftMenu, titleVisibility: .visible) {
            if let index = selectedGiftIndex {
                if wornGifts.contains(index) {
                    Button("Снять подарок") {
                        wornGifts.remove(index)
                    }
                } else {
                    Button("Надеть подарок") {
                        wornGifts.insert(index)
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
}

#Preview {
    ProfilereelsView()
}