import Foundation
import Combine

class PlannerData: ObservableObject {
    @Published var tasksByDay: [String: [String]] = [:] {
        didSet {
            save()
        }
    }

    init() {
        load()
    }

    func addTask(for day: String, task: String) {
        tasksByDay[day, default: []].append(task)
    }

    func deleteTask(for day: String, at index: Int) {
        tasksByDay[day]?.remove(at: index)
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(tasksByDay) {
            UserDefaults.standard.set(encoded, forKey: "savedPlannerTasks")
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: "savedPlannerTasks"),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            tasksByDay = decoded
        }
    }
}

