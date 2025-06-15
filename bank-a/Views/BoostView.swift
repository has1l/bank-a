import SwiftUI
import AVKit

struct BoostPost: Identifiable, Codable {
    let id: Int
    let user_id: Int
    let video_url: String
    let title: String
    let created_at: String

    var videoURL: URL {
        URL(string: video_url) ?? URL(string: "https://example.com/fallback.mp4")!
    }
}

struct BoostResponse: Codable {
    let success: Bool
    let data: [BoostPost]
}

struct BoostView: View {
    @State private var posts: [BoostPost] = []

    var body: some View {
        NavigationView {
            TabView {
                ForEach(posts) { post in
                    ZStack {
                        GeometryReader { geometry in
                            ZStack {
                                Color.black
                                VStack {
                                    Spacer(minLength: geometry.safeAreaInsets.top)

                                    VideoPlayer(player: AVPlayer(url: post.videoURL))
                                        .aspectRatio(9/16, contentMode: .fit)
                                        .frame(width: geometry.size.width * 0.95)
                                        .clipped()
                                        .cornerRadius(10)

                                    Spacer(minLength: geometry.safeAreaInsets.bottom + 60) // учёт tabBar
                                }
                            }
                            .ignoresSafeArea(.all, edges: [.top]) // не перекрывать нижнюю часть
                        }

                        VStack {
                            HStack {
                                Spacer()
                                NavigationLink(destination: ProfilereelsView()) {
                                    Image(systemName: "person.circle")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 60) // учёт статус-бара и острова
                                .padding(.trailing, 20)
                            }
                            Spacer()
                        }

                        VStack {
                            Spacer()
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("@username")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text(post.title)
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                }
                                Spacer()
                                VStack(spacing: 20) {
                                    Button(action: {}) {
                                        Image(systemName: "heart.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                    Button(action: {}) {
                                        Image(systemName: "message.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                    Button(action: {}) {
                                        Image(systemName: "square.and.arrow.up.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                    Button(action: {}) {
                                        VStack {
                                            Image(systemName: "person.crop.circle.fill")
                                                .font(.title2)
                                            Text("Подписаться")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.white)
                                    }
                                }
                                .padding(.trailing)
                                .padding(.top, 100)
                            }
                            .padding(.bottom, 80) // учёт tabBar
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            .navigationBarHidden(true)
        }
        .onAppear {
            fetchBoosts(for: "+7 (777) 777-77-77") { result in
                self.posts = result
            }
        }
    }

    func fetchBoosts(for phone: String, completion: @escaping ([BoostPost]) -> Void) {
        guard let encodedPhone = phone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://localhost:3001/boosts?phone=\(encodedPhone)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(BoostResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(decoded.data)
                }
            } catch {
                print("Ошибка парсинга: \(error)")
            }
        }.resume()
    }
}