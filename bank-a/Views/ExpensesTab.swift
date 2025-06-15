import SwiftUI

struct ExpensesTab: View {
    @AppStorage("currentUserPhone") var userPhone: String = ""
    @State private var entries: [YesterdayView.ExpenseEntry] = []
    @State private var currentCategory = ""
    @State private var currentSubcategory = ""
    @State private var currentAmount = ""
    @State private var selectedTime = Date()
    @State private var gptResponse = ""
    @State private var isLoading = false

    var body: some View {
        // Log onAppear before NavigationView
        NavigationView {
            VStack {
                Picker(selection: $selectedDay, label: Text("Выберите день")) {
                    Text("Вчера").tag("yesterday")
                    Text("Сегодня").tag("today")
                    Text("Завтра").tag("tomorrow")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if selectedDay == "yesterday" {
                    YesterdayView(
                        entries: $entries,
                        currentCategory: $currentCategory,
                        currentSubcategory: $currentSubcategory,
                        currentAmount: $currentAmount,
                        selectedTime: $selectedTime,
                        gptResponse: $gptResponse,
                        isLoading: $isLoading,
                        phone: userPhone
                    )
                } else if selectedDay == "today" {
                    TodayView(phone: userPhone)
                } else {
                    TomorrowView()
                }
            }
            .navigationTitle("Траты")
        }
        .onAppear {
            print("📲 currentUserPhone в ExpensesTab через AppStorage: \(userPhone)")
        }
    }

    @State private var selectedDay = "today"
}

struct YesterdayView: View {
    struct ExpenseEntry: Codable {
        var category: String
        var subcategory: String
        var amount: String
        var time: String
    }
    @Binding var entries: [ExpenseEntry]
    @Binding var currentCategory: String
    @Binding var currentSubcategory: String
    @Binding var currentAmount: String
    @Binding var selectedTime: Date
    @AppStorage("savedCategories") var savedCategories: String = ""
    @AppStorage("savedAmounts") var savedAmounts: String = ""
    @State var savedAdvice: String = ""
    @Binding var gptResponse: String
    @Binding var isLoading: Bool
    let phone: String
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        VStack(spacing: 12) {
            TextField("Категория (например, еда)", text: $currentCategory)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Подкатегория (например, ресторан)", text: $currentSubcategory)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Сумма (например, 250)", text: $currentAmount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .keyboardType(.decimalPad)

            DatePicker("Время", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .padding(.horizontal)

            Button("Добавить") {
                if !currentCategory.isEmpty && !currentAmount.isEmpty {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    let entry = ExpenseEntry(category: currentCategory, subcategory: currentSubcategory, amount: currentAmount, time: formatter.string(from: selectedTime))
                    entries.append(entry)
                    currentCategory = ""
                    currentSubcategory = ""
                    currentAmount = ""
                }
            }

            if !entries.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(entries, id: \.time) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(entry.category) - \(entry.subcategory)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("в \(entry.time)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("\(entry.amount)₽")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                }

                Button("Проанализировать") {
                    sendDataToGPT()
                }
                .padding(.top)
            }

            if isLoading {
                ProgressView("Анализируем...")
                    .padding(.top)
            }

            if !savedAdvice.isEmpty {
                Text("🎯 Совет: \(savedAdvice)")
                    .foregroundColor(.blue)
                    .padding()
            }

            Button("🧹 Сбросить совет") {
                print("🧹 Отправка запроса на удаление совета из БД")
                guard let url = URL(string: "http://localhost:3001/resetAdviceOnly") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let phonePayload = ["phone": phone]
                guard let httpBody = try? JSONSerialization.data(withJSONObject: phonePayload, options: []) else {
                    print(" Ошибка сериализации JSON для сброса совета")
                    return
                }
                request.httpBody = httpBody

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print(" Ошибка при удалении совета: \(error.localizedDescription)")
                    } else if let data = data {
                        let responseText = String(data: data, encoding: .utf8) ?? "не удалось декодировать"
                        print("Ответ от сервера на сброс совета: \(responseText)")
                        DispatchQueue.main.async {
                            savedAdvice = ""
                        }
                    }
                }.resume()
            }
            .padding(.top)

        }
        .padding()
        .onAppear {
            print("👀 onAppear — получение совета для вчерашнего дня")
            print("📲 savedPhone в YesterdayView (через props): \(phone)")
            print("🌐 Загружаем совет из БД по номеру: \(phone)")
            guard let url = URL(string: "http://localhost:3001/advice?phone=\(phone)") else { return }
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, error == nil {
                    print(" Получены данные совета из БД: \(String(data: data, encoding: .utf8) ?? "не удалось декодировать")")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print(" JSON из БД: \(json)")
                        if let adviceText = json["advice"] as? String, !adviceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            DispatchQueue.main.async {
                                print(" Совет из БД: \(adviceText)")
                                savedAdvice = adviceText
                                gptResponse = adviceText
                            }
                        } else {
                            print("ℹ Совет пустой — ничего не отображаем")
                        }
                    } else {
                        print(" Ошибка парсинга совета из БД")
                    }
                } else {
                    print(" Ошибка загрузки данных совета: \(error?.localizedDescription ?? "неизвестная ошибка")")
                }
            }.resume()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                print("🧹 Уходим в фон — сбрасываем совет")
                savedAdvice = ""
            }
        }
    }

    func sendDataToGPT() {
        isLoading = true
        let expenses = entries.map { "\($0.category) (\($0.time)): \($0.amount)₽" }.joined(separator: ", ")
        print("📤 Отправляем расходы: \(expenses)")
        let userKey = phone
        print("📲 Отправляем с номером телефона: \(userKey)")
        let body: [String: Any] = ["expenses": expenses, "phone": userKey]

        let url = URL(string: "http://localhost:3001/analyzeYesterday")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, error == nil {
                print(" Ответ от GPT-сервера:")
                print(String(data: data, encoding: .utf8) ?? " Не удалось декодировать ответ")
                print(" Получен ответ от GPT")
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tasksArray = json["tasks"] as? [String],
                   let adviceText = json["advice"] as? String {
                    print(" Разобран JSON: tasks = \(tasksArray), advice = \(adviceText)")
                    print("Отправка совета и заданий в БД...")
                    DispatchQueue.main.async {
                        let userKey = phone
                        // Отправка совета в БД с привязкой к пользователю
                        let adviceUrl = URL(string: "http://localhost:3001/advice")!
                        var adviceRequest = URLRequest(url: adviceUrl)
                        adviceRequest.httpMethod = "POST"
                        adviceRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        let adviceBody: [String: Any] = ["phone": userKey, "advice": adviceText]
                        adviceRequest.httpBody = try? JSONSerialization.data(withJSONObject: adviceBody)
                        URLSession.shared.dataTask(with: adviceRequest).resume()
                        print(" Совет отправлен на \(adviceUrl)")
                        savedAdvice = adviceText
                        gptResponse = ""
                        // Удаляем старые задания этого пользователя (с phone)
                        let deleteTasksUrl = URL(string: "http://localhost:3001/tasks?phone=\(userKey)")!
                        var deleteRequest = URLRequest(url: deleteTasksUrl)
                        deleteRequest.httpMethod = "DELETE"
                        URLSession.shared.dataTask(with: deleteRequest).resume()
                        print("🧹 Запрос на удаление старых заданий отправлен на \(deleteTasksUrl)")
                        // Отправка новых заданий в БД с phone
                        let tasksUrl = URL(string: "http://localhost:3001/tasks")!
                        var tasksRequest = URLRequest(url: tasksUrl)
                        tasksRequest.httpMethod = "POST"
                        tasksRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        let tasksBody: [String: Any] = ["phone": userKey, "tasks": tasksArray]
                        tasksRequest.httpBody = try? JSONSerialization.data(withJSONObject: tasksBody)
                        URLSession.shared.dataTask(with: tasksRequest).resume()
                        print(" Новые задания отправлены на \(tasksUrl)")
                        isLoading = false
                    }
                } else {
                    print(" Не удалось распарсить JSON или данные отсутствуют")
                    DispatchQueue.main.async {
                        gptResponse = " Ошибка анализа"
                        isLoading = false
                    }
                }
            } else {
                print(" Ошибка или пустые данные: \(error?.localizedDescription ?? "нет описания")")
                print(" Не удалось распарсить JSON или данные отсутствуют")
                DispatchQueue.main.async {
                    gptResponse = " Ошибка анализа"
                    isLoading = false
                }
            }
        }.resume()
    }
}

struct TodayView: View {
    let phone: String
    @State private var gptResponse: String = ""
    @State private var completedTasks: Set<String> = []
    @State private var isLoading = false
    @State private var tasks: [String] = []
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("appLaunched") var appLaunched: Bool = false
    @State private var userScoreFromDB: Int = 0
    @State private var entries: [YesterdayView.ExpenseEntry] = []
    @State private var currentCategory = ""
    @State private var currentSubcategory = ""
    @State private var currentAmount = ""
    @State private var selectedTime = Date()
    @State private var score: Int = 0
    @State private var completedTodayTasks: [String] = []
    @State private var todayAdvice: String = ""
    @State private var showResultsSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Твои баллы: \(userScoreFromDB)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)

                // Форма ввода трат
                TextField("Категория", text: $currentCategory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Подкатегория", text: $currentSubcategory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Сумма", text: $currentAmount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                DatePicker("Время", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Button("Добавить трату") {
                    if !currentCategory.isEmpty && !currentAmount.isEmpty {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        let entry = YesterdayView.ExpenseEntry(category: currentCategory, subcategory: currentSubcategory, amount: currentAmount, time: formatter.string(from: selectedTime))
                        entries.append(entry)
                        print("➕ Добавлена трата: \(entry)")
                        currentCategory = ""
                        currentSubcategory = ""
                        currentAmount = ""
                    }
                }

                // Список введённых трат (как во YesterdayView)
                if !entries.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(entries, id: \.time) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(entry.category) - \(entry.subcategory)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("в \(entry.time)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text("\(entry.amount)₽")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                        }
                    }
                }

                // Список заданий на сегодня
                if !tasks.isEmpty {
                    Text("🧠 Задания на сегодня:")
                        .font(.headline)
                    ForEach(tasks, id: \.self) { task in
                        HStack {
                            Text(task)
                            Spacer()
                            if completedTasks.contains(task) {
                                Text("✅")
                            }
                        }
                        .onTapGesture {
                            completedTasks.insert(task)
                        }
                    }
                }

                // Кнопка анализа трат и заданий
                if !entries.isEmpty && !tasks.isEmpty && !showResultsSheet {
                    Button {
                        isLoading = true
                        analyzeToday {
                            showResultsSheet = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Проанализировать траты")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                }

                if isLoading {
                    ProgressView("Анализируем...")
                        .padding(.top)
                }

                if !gptResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        let lines = gptResponse.components(separatedBy: "\n").filter { !$0.isEmpty }
                        ForEach(lines, id: \.self) { line in
                            Text(line)
                                .foregroundColor(.blue)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top)
                }

                Button("🧹 Сбросить задания") {
                    print("🧹 Отправка запроса на удаление заданий из БД")
                    guard let url = URL(string: "http://localhost:3001/resetTasksOnly") else { return }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let phonePayload = ["phone": phone]
                    guard let httpBody = try? JSONSerialization.data(withJSONObject: phonePayload, options: []) else {
                        print(" Ошибка сериализации JSON для сброса заданий")
                        return
                    }
                    request.httpBody = httpBody

                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if let error = error {
                            print(" Ошибка при удалении заданий: \(error.localizedDescription)")
                        } else if let data = data {
                            let responseText = String(data: data, encoding: .utf8) ?? "не удалось декодировать"
                            print("Ответ от сервера на сброс заданий: \(responseText)")
                            DispatchQueue.main.async {
                                tasks = []
                            }
                        }
                    }.resume()
                }
                .padding(.top)
            }
            .padding()
        }
        .onAppear {
            let userKey = phone
            print(" savedPhone в TodayView (через props): \(userKey)")
            if userKey.isEmpty {
                print(" Переданный номер телефона пустой")
            } else {
                print("Номер телефона получен: \(userKey)")
                fetchUserScoreFromDB(phone: userKey)
                fetchTasksForUser(phone: userKey)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                print(" Уход в фон — сбрасываем флаг запуска")
                appLaunched = false

            }
        }
        .sheet(isPresented: $showResultsSheet) {
            VStack(alignment: .leading, spacing: 16) {
                if !completedTodayTasks.isEmpty {
                    Text("Выполненные задания:")
                        .font(.headline)
                    ForEach(completedTodayTasks, id: \.self) { task in
                        Text("• \(task)")
                    }
                }
                Text("🏅 Баллов: \(score)")
                    .font(.headline)
                if !todayAdvice.isEmpty {
                    Text("🎯 Совет: \(todayAdvice)")
                        .foregroundColor(.blue)
                        .font(.headline)
                }
                Button("Закрыть") {
                    showResultsSheet = false
                }
                .padding(.top)
            }
            .padding()
            .presentationDetents([.medium, .large])
        }
    }

    func fetchTasksForUser(phone: String) {
        print(" Получен номер телефона в TodayView: '\(phone)'")
        print(" Запрос на получение заданий из БД для телефона: \(phone)")
        guard let url = URL(string: "http://localhost:3001/tasks?phone=\(phone)") else {
            print(" Неверный URL для получения заданий")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print(" Ошибка при загрузке заданий: \(error.localizedDescription)")
                return
            }

            if let data = data, error == nil {
                print(" Ответ от сервера (tasks):")
                print(String(data: data, encoding: .utf8) ?? " Не удалось декодировать")

                if let array = try? JSONSerialization.jsonObject(with: data) as? [String], !array.isEmpty {
                    print(" Распарсено как [String]: \(array)")
                    DispatchQueue.main.async {
                        tasks = array
                    }
                } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let tasksArray = json["tasks"] as? [String] {
                    print("Распарсено из JSON-объекта (может быть пусто): \(tasksArray)")
                    DispatchQueue.main.async {
                        tasks = tasksArray
                    }
                } else {
                    print(" JSON не распарсился. Возможно, tasks пустой или в другом формате.")
                }
            } else {
                print(" Данные не получены от сервера")
            }
        }.resume()
    }

    // Функция анализа выполнения заданий по тратам, с completion для sheet
    func analyzeToday(completion: (() -> Void)? = nil) {
        isLoading = true
        let expensesDict = entries.map { [
            "category": $0.category,
            "subcategory": $0.subcategory,
            "amount": $0.amount,
            "time": $0.time
        ]}

        let body: [String: Any] = [
            "phone": phone,
            "expenses": expensesDict,
            "tasks": tasks
        ]

        print("📤 Отправляем запрос на анализ выполнения заданий с телом:")
        print("📱 Телефон: \(phone)")
        print("💸 Траты: \(expensesDict)")
        print("📋 Задания: \(tasks)")

        let url = URL(string: "http://localhost:3001/analyzeToday")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { isLoading = false }
            if let data = data, error == nil {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let completedTasksList = json["completedTasks"] as? [String],
                   let scoreValue = json["score"] as? Int,
                   let todayAdviceValue = json["advice"] as? String {
                    print(" Ответ от analyzeToday: \(json)")
                    DispatchQueue.main.async {
                        completedTodayTasks = completedTasksList
                        score = scoreValue
                        todayAdvice = todayAdviceValue
                        print(" Обновлён интерфейс с выполненными задачами, баллами и советом")

                        // Обновляем баллы в БД
                        let updateScoreUrl = URL(string: "http://localhost:3001/score")!
                        var updateRequest = URLRequest(url: updateScoreUrl)
                        updateRequest.httpMethod = "POST"
                        updateRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        let updateBody: [String: Any] = ["phone": phone, "scoreDelta": scoreValue]
                        updateRequest.httpBody = try? JSONSerialization.data(withJSONObject: updateBody)
                        URLSession.shared.dataTask(with: updateRequest).resume()
                        print(" Отправили \(scoreValue) баллов на сервер для обновления")

                        fetchUserScoreFromDB(phone: phone)
                        completion?()
                    }
                } else {
                    print(" Ошибка парсинга ответа от analyzeToday")
                    print(" JSON (raw): \(String(data: data, encoding: .utf8) ?? "не удалось декодировать")")
                }
            } else {
                print(" Ошибка запроса analyzeToday: \(error?.localizedDescription ?? "нет описания")")
            }
        }.resume()
    }

    func fetchUserScoreFromDB(phone: String) {
        guard let url = URL(string: "http://localhost:3001/score?phone=\(phone)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil {
                print(" Полученные данные по баллам: \(String(data: data, encoding: .utf8) ?? "не удалось декодировать")")
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let score = json["score"] as? Int {
                        print(" Распарсенные баллы: \(score)")
                        DispatchQueue.main.async {
                            self.userScoreFromDB = score
                            print(" Баллы из БД: \(score)")
                        }
                    } else {
                        print(" Поле 'score' отсутствует или не Int в JSON: \(json)")
                    }
                } else {
                    print(" Ошибка парсинга данных баллов")
                }
            } else {
                print(" Ошибка получения баллов из БД: \(error?.localizedDescription ?? "неизвестная ошибка")")
            }
        }.resume()
    }
}

struct TomorrowView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🧠 Задания на завтра:")
                .font(.headline)
            Text("1. Не покупать кофе — сэкономишь 150₽")
            Text("2. Пройтись пешком вместо такси")
            Text("3. Сделать ланч дома")
            Text("🎯 Общее: потратить не больше 300₽ за день")
        }
        .padding()
    }
}
