import Foundation
import Combine

struct Note: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var content: String
    var color: String
    var createdAt: Date
    var updatedAt: Date
}

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let saveKey = "BlitzNotesData"

    init() {
        loadNotes()
        
        $notes
            .dropFirst()
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveNotes()
            }
            .store(in: &cancellables)
    }
    
    func addNote() -> Note {
        let note = Note(title: "", content: "", color: "yellow", createdAt: Date(), updatedAt: Date())
        notes.insert(note, at: 0)
        return note
    }
    
    func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            self.notes = decoded
        }
    }
    
    func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}
