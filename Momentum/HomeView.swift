
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var plannerData: PlannerData
    
    @State private var habits: [Habit] = []
    @State private var currentQuoteIndex = 0
    @State private var newHabit: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    @State private var completedDays: [String: Bool] = [:]
    @State private var animateStreak = false
    let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    @State private var didLoadTodayPlannedTasks = false
    @State private var isLoadingHabits = false
    @State private var errorMessage: String? = nil

    private let firestore = FirestoreManager()

    let quotes = [
        "Discipline > Motivation.", "Small steps every day.", "You are your habits.",
        "One day or day one — you decide.", "Comfort is a slow death. Pick struggle.",
        "Consistency creates results.", "No one is coming to save you.",
        "You don’t get what you wish for. You get what you work for.",
        "Tired? Do it tired.", "Push through. No one’s clapping now, but they will later."
    ]

    // Computed properties
    var completedCount: Int { habits.filter { $0.isCompleted }.count }
    var progress: Double { habits.isEmpty ? 0 : Double(completedCount) / Double(habits.count) }
    var currentDayName: String { let f = DateFormatter(); f.dateFormat = "EEEE"; return f.string(from: Date()) }
    var streakCount: Int { completedDays.values.filter { $0 }.count }


    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0F2027"), Color(hex: "#203A43"), Color(hex: "#2C5364")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 15) { // Reduced spacing slightly
                    // Header
                    HStack(spacing: 12) {
                         Text("\u{1F525} Momentum")
                             .font(.system(size: 34, weight: .bold, design: .rounded))
                             .foregroundColor(.white)
                         Spacer()
                         Button(action: authManager.logout) { /* Logout Button Styling */
                             Image(systemName: "rectangle.portrait.and.arrow.right")
                                 .font(.title2).foregroundColor(.white).padding(10)
                                 .background(Color.red.opacity(0.8)).clipShape(Circle())
                         }
                         NavigationLink(destination: PlannerView()) { /* Planner Button Styling */
                             Image(systemName: "calendar")
                                 .font(.title2).foregroundColor(.white).padding(10)
                                 .background(Color.blue.opacity(0.8)).clipShape(Circle())
                         }
                     }
                    .padding(.horizontal)
                    .padding(.top) // Add padding at the top

                    // Progress Circle
                    ZStack {
                        Circle().stroke(lineWidth: 12).opacity(0.15).foregroundColor(.white)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(progress))
                            .stroke(
                                AngularGradient(gradient: Gradient(colors: [.green, .cyan]), center: .center),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.6), value: progress)
                        Text("\(Int(progress * 100))%")
                             .font(.system(size: 18, weight: .semibold, design: .rounded))
                             .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 100)

                    // Quote Text
                    Text("\(quotes[currentQuoteIndex])")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9)).multilineTextAlignment(.center)
                        .padding(.horizontal).transition(.opacity.animation(.easeInOut))
                        .id(currentQuoteIndex) // Ensures transition happens when index changes
                        .onReceive(timer) { _ in
                            withAnimation {
                                currentQuoteIndex = Int.random(in: 0..<quotes.count)
                            }
                        }

                    // Add Habit Input
                     HStack {
                         TextField("New habit...", text: $newHabit)
                             .font(.system(size: 16, design: .rounded)).padding(12)
                             .background(Color.white.opacity(0.1)).cornerRadius(12)
                             .foregroundColor(.white)
                             .focused($isTextFieldFocused)
                             .onSubmit(addHabit) // Allow adding via return key

                         Button(action: addHabit) {
                             Image(systemName: "plus")
                                 .font(.title2).foregroundColor(.white).padding(10)
                                 .background(Color.green.opacity(0.8)).clipShape(Circle())
                         }
                     }
                    .padding(.horizontal)

                    // --- Habits List Area ---
                    if isLoadingHabits {
                        Spacer()
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).padding()
                        Spacer()
                    } else if let errorMsg = errorMessage {
                        Spacer()
                        Text("Error loading habits: \(errorMsg)")
                            .foregroundColor(.red).padding()
                        Spacer()
                    } else if habits.isEmpty && !isLoadingHabits {
                         Spacer()
                         Text("No habits yet. Add one above!")
                             .foregroundColor(.gray)
                             .padding()
                         Spacer()
                    } else {
                        List {
                            // Use identifiableId from Habit struct
                            ForEach($habits, id: \.identifiableId) { $habit in
                                Button(action: { toggleCompletion(for: habit) }) {
                                    HabitRow(habit: habit) // Use extracted Row View
                                }
                                // Apply modifiers directly to the row content for better interaction
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)) // Adjust spacing
                            }
                            .onDelete(perform: deleteHabits) // Use plural form consistent with signature
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden) // Make List background clear
                        .padding(.top, 5)
                    }
                    // --- End Habits List Area ---


                    // Streak Display
                    VStack(spacing: 6) {
                         Text("\u{1F525} \(streakCount)-day streak") // Logic unchanged
                            .font(.subheadline).foregroundColor(.white.opacity(0.85))
                            .scaleEffect(animateStreak ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: animateStreak)
                         HStack(spacing: 8) {
                             ForEach(weekDays.indices, id: \.self) { index in
                                 let day = weekDays[index]
                                 RoundedRectangle(cornerRadius: 4)
                                     .fill(completedDays[day] == true ? Color.green : Color.gray.opacity(0.3))
                                     .frame(width: 20, height: 20)
                                     .overlay(Text(day).font(.caption2).foregroundColor(.white.opacity(0.8)))
                             }
                         }
                     }
                    .padding(.bottom, 10)
                }
                // Removed outer .padding(.vertical) to use Spacer effectively
            }
            .navigationBarHidden(true)
            .onAppear(perform: initialLoad) // Load data when view appears
            .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { _ in
                 // Clear local data on logout
                habits = []
                completedDays = [:]
                didLoadTodayPlannedTasks = false
                errorMessage = nil
            }
        }
         // Needs environment objects from AuthRouter/App
         .environmentObject(authManager)
         .environmentObject(plannerData)
    }
    
    // MARK: - Habit Row View
    struct HabitRow: View {
        let habit: Habit

        var body: some View {
             HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .strikethrough(habit.isCompleted, color: .white.opacity(0.7))
                    Text(habit.isCompleted ? "Completed" : "In Progress")
                        .font(.caption).foregroundColor(habit.isCompleted ? .green.opacity(0.8) : .gray)
                }
                Spacer()
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(habit.isCompleted ? .green : .white.opacity(0.3))
                    .font(.title2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: habit.isCompleted) // Animate just the icon change
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 3)
            )
        }
    }

    // MARK: - Data Functions
    func initialLoad() {
        if habits.isEmpty && authManager.isLoggedIn && !isLoadingHabits {
             loadHabitsFromFirestore()
        }
        loadStreak() // Load local streak data
    }

    func loadHabitsFromFirestore() {
        isLoadingHabits = true
        errorMessage = nil
        firestore.loadHabits { result in
            isLoadingHabits = false
            switch result {
            case .success(let loadedHabits):
                self.habits = loadedHabits.sorted { !$0.isCompleted && $1.isCompleted } // Sort incomplete first
                print("Successfully loaded \(loadedHabits.count) habits.")
                mergePlannerTasks()
                updateStreak()
            case .failure(let error):
                print("Error loading habits: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func mergePlannerTasks() {
         if !didLoadTodayPlannedTasks, let todayTasks = plannerData.tasksByDay[currentDayName] {
             var addedPlannerHabits = false
             var habitsToSave: [Habit] = [] // Collect habits to save
             for task in todayTasks {
                 if !habits.contains(where: { $0.name == task }) {
                     // Use nil for ID, Firestore will generate one if not provided via identifiableId logic
                     let newPlannerHabit = Habit(id: nil, name: task, isCompleted: false)
                     habits.append(newPlannerHabit) // Add locally first
                     habitsToSave.append(newPlannerHabit)
                     addedPlannerHabits = true
                 }
             }
             // Save all newly added planner habits
             for habit in habitsToSave {
                 saveHabitToFirestore(habit)
             }
             if addedPlannerHabits {
                 print("Merged planner tasks into habits for today.")
                 // Optionally sort habits again after adding
                 self.habits.sort { !$0.isCompleted && $1.isCompleted }
             }
             didLoadTodayPlannedTasks = true
         }
    }

    func addHabit() {
        let trimmed = newHabit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Use nil for ID, Firestore generates it
        let newHabitItem = Habit(id: nil, name: trimmed, isCompleted: false)
        
        withAnimation(.spring()) {
            habits.append(newHabitItem)
            // Sort after adding
            habits.sort { !$0.isCompleted && $1.isCompleted }
            newHabit = ""
            isTextFieldFocused = false
        }
        saveHabitToFirestore(newHabitItem)
    }

    func toggleCompletion(for habit: Habit) {
        // Find index using identifiableId which handles both local/firestore IDs
        guard let index = habits.firstIndex(where: { $0.identifiableId == habit.identifiableId }) else { return }

        var habitToUpdate = habits[index]
        habitToUpdate.isCompleted.toggle()

        withAnimation(.easeInOut(duration: 0.2)) { // Faster animation
             habits[index] = habitToUpdate
             // Re-sort after toggling completion status
             habits.sort { !$0.isCompleted && $1.isCompleted }
        }
        
        updateStreak() // Update streak logic (local)
        animateStreak.toggle()
        saveHabitToFirestore(habitToUpdate) // Save the updated habit
    }
    
    // Changed name to plural to match ForEach modifier
    func deleteHabits(at offsets: IndexSet) {
        let habitsToDelete = offsets.map { habits[$0] }
        
        // Perform UI deletion first for responsiveness
        withAnimation {
             habits.remove(atOffsets: offsets)
        }
        
        // Delete from Firestore
        for habit in habitsToDelete {
             // Ensure the habit has an ID from Firestore before trying to delete
             guard habit.id != nil else {
                 print("Skipping deletion for habit '\(habit.name)' because it lacks a Firestore ID.")
                 continue
             }
             firestore.deleteHabit(habit) { result in
                 if case .failure(let error) = result {
                     print("Error deleting habit \(habit.name) from Firestore: \(error.localizedDescription)")
                     self.errorMessage = "Failed to delete '\(habit.name)'"
                     // Optionally add the habit back to the list or handle error more gracefully
                 }
             }
        }
        updateStreak() // Update streak after deletion
    }

    func saveHabitToFirestore(_ habit: Habit) {
        firestore.saveHabit(habit) { result in
            if case .failure(let error) = result {
                 print("Error saving habit \(habit.name) to Firestore: \(error.localizedDescription)")
                 self.errorMessage = "Failed to save '\(habit.name)'"
                 // Maybe trigger a reload or show more prominent error
            }
            // No need to do anything on success with optimistic updates,
            // unless you need the potentially updated habit object (e.g., with generated ID)
        }
    }

    // --- Streak Functions (Unchanged - Using UserDefaults) ---
    func updateStreak() {
        let todayIndex = Calendar.current.component(.weekday, from: Date()) - 1 // 0=Sun, 1=Mon...
        guard todayIndex >= 0 && todayIndex < weekDays.count else { return }
        let todayInitial = weekDays[todayIndex]
        // Mark day complete if ANY habit is completed
        completedDays[todayInitial] = habits.contains { $0.isCompleted }
        saveStreak()
    }
    func saveStreak() {
        if let encoded = try? JSONEncoder().encode(completedDays) {
            UserDefaults.standard.set(encoded, forKey: "completedDays")
        }
    }
    func loadStreak() {
        if let data = UserDefaults.standard.data(forKey: "completedDays"),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            completedDays = decoded
        } else {
             completedDays = [:] // Initialize if not found
        }
    }
}
