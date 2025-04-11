import SwiftUI

struct PlannerView: View {
    @EnvironmentObject var plannerData: PlannerData
    @State private var selectedDay: String? = nil
    @State private var newTask: String = ""

    let allDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#141E30"), Color(hex: "#243B55")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Text("\u{1F4C5} Weekly Planner")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding(.top)

                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 16) {
                    ForEach(allDays, id: \ .self) { day in
                        Button(action: {
                            withAnimation {
                                selectedDay = day
                            }
                        }) {
                            Text(day)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(selectedDay == day ? 0.2 : 0.1))
                                .cornerRadius(14)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()

                if let day = selectedDay {
                    Text("\u{1F4C6} Tasks for \(day)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.top)

                    HStack {
                        TextField("Add task for \(day)", text: $newTask)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)

                        Button(action: {
                            let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            withAnimation {
                                plannerData.addTask(for: day, task: trimmed)
                                newTask = ""
                            }
                        }) {
                            Text("Add")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(plannerData.tasksByDay[day, default: []].indices, id: \ .self) { index in
                                let task = plannerData.tasksByDay[day]![index]

                                HStack(spacing: 12) {
                                    Image(systemName: "pencil.and.outline")
                                        .foregroundColor(.yellow)
                                        .font(.title3)

                                    Text(task)
                                        .foregroundColor(.white)
                                        .font(.body)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    Button(action: {
                                        newTask = task
                                        withAnimation {
                                            plannerData.deleteTask(for: day, at: index)
                                        }
                                    }) {
                                        Image(systemName: "square.and.pencil")
                                            .foregroundColor(.blue)
                                    }

                                    Button(action: {
                                        withAnimation {
                                            plannerData.deleteTask(for: day, at: index)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                .padding(.horizontal)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
                } else {
                    Spacer()
                }
            }
            .padding(.top)
        }
    }
}
