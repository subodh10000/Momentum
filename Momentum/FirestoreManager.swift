
import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreManager {
    private let db = Firestore.firestore()

    var userId: String? { Auth.auth().currentUser?.uid }

    private func habitsCollectionRef(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("habits")
    }

    // MARK: - Save / Update Single Habit
    func saveHabit(_ habit: Habit, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = userId else {
            completion(.failure(NSError(domain: "FirestoreManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        let docId = habit.identifiableId
        
        do {
            try habitsCollectionRef(for: uid).document(docId).setData(from: habit) { error in
                if let error = error {
                    print("❌ Failed to save habit \(docId): \(error)")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            print("❌ Failed to encode habit \(habit.name): \(error)")
            completion(.failure(error))
        }
    }

    // MARK: - Delete Habit
    func deleteHabit(_ habit: Habit, completion: @escaping (Result<Void, Error>) -> Void) {
         guard let uid = userId else {
            completion(.failure(NSError(domain: "FirestoreManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
         let docId = habit.identifiableId
         guard habit.id != nil else {
              completion(.failure(NSError(domain: "FirestoreManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Habit has no Firestore ID to delete"])))
              return
         }
        
        habitsCollectionRef(for: uid).document(docId).delete { error in
             if let error = error {
                 print("❌ Failed to delete habit \(docId): \(error)")
                 completion(.failure(error))
            } else {
                 print("🗑️ Habit \(docId) deleted successfully.")
                 completion(.success(()))
            }
        }
    }

    // MARK: - Load Habits
    func loadHabits(completion: @escaping (Result<[Habit], Error>) -> Void) {
        guard let uid = userId else {
            completion(.failure(NSError(domain: "FirestoreManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }

        habitsCollectionRef(for: uid).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("❌ Error getting habits: \(error)")
                completion(.failure(error))
                return
            }

            guard let documents = querySnapshot?.documents else {
                completion(.success([]))
                return
            }

            let habits = documents.compactMap { document -> Habit? in
                do {
                    return try document.data(as: Habit.self)
                } catch {
                    print("⚠️ Failed to decode habit document \(document.documentID): \(error)")
                    return nil
                }
            }
            
            print("✅ Loaded \(habits.count) habits for user: \(uid)")
            completion(.success(habits))
        }
    }
    
}
