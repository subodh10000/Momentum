import Foundation
import FirebaseFirestore

struct Habit: Identifiable, Codable, Equatable {
    @DocumentID var id: String?

    var name: String
    var isCompleted: Bool
    

    var identifiableId: String {
        id ?? UUID().uuidString 
    }
}
