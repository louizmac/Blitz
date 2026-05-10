import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: NoteStore
    @State private var selectedNoteId: UUID?
    @State private var searchText = ""
    @State private var isTargeted = false
    
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false

    var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            
            Group {
                if let id = selectedNoteId, let binding = binding(for: id) {
                    EditView(note: binding, onBack: { selectedNoteId = nil })
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    ListView(selectedNoteId: $selectedNoteId, searchText: $searchText, hasSeenTutorial: $hasSeenTutorial)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .padding(14)
            
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isTargeted ? Color.accentColor : Color.clear, lineWidth: 3)
                .padding(2)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)

            if !hasSeenTutorial {
                OnboardingView(isVisible: $hasSeenTutorial)
            }
        }
        .frame(width: 280, height: 380)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedNoteId)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in isTargeted = true }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            isTargeted = false
            store.saveNotes()
        }
    }
    
    private func binding(for id: UUID) -> Binding<Note>? {
        guard let index = store.notes.firstIndex(where: { $0.id == id }) else { return nil }
        return $store.notes[index]
    }
}

struct OnboardingView: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            VStack(spacing: 20) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                
                Text("Welcome to Blitz")
                    .font(.system(size: 20, weight: .bold))
                
                VStack(alignment: .leading, spacing: 12) {
                    TutorialItem(icon: "keyboard", text: "Toggle this panel with **Cmd + Shift + L** from anywhere.")
                    TutorialItem(icon: "plus.circle", text: "Click '+' to create a new quick note.")
                    TutorialItem(icon: "cursorarrow.and.square.on.square", text: "Drag the window to move it.")
                    TutorialItem(icon: "contextualmenu.and.cursorarrow", text: "Right-click the Menu Bar icon to quit.")
                }
                .padding(.horizontal)
                
                Button(action: {
                    withAnimation { isVisible = true }
                }) {
                    Text("Got it!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding()
        }
    }
}

struct TutorialItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            Text(LocalizedStringKey(text))
                .font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ListView: View {
    @EnvironmentObject var store: NoteStore
    @Binding var selectedNoteId: UUID?
    @Binding var searchText: String
    @Binding var hasSeenTutorial: Bool
    
    var filteredNotes: [Note] {
        if searchText.isEmpty { return store.notes }
        return store.notes.filter {
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                
                Button(action: {
                    withAnimation {
                        hasSeenTutorial = false
                    }
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                
                Button(action: {
                    let newNote = store.addNote()
                    selectedNoteId = newNote.id
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            
            List {
                ForEach(filteredNotes) { note in
                    NoteRow(note: note)
                        .onTapGesture { selectedNoteId = note.id }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    store.notes.removeAll { $0.id == note.id }
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    store.notes.removeAll { $0.id == note.id }
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

struct NoteRow: View {
    let note: Note
    @State private var copied = false
    
    var displayTitle: String {
        if !note.title.trimmingCharacters(in: .whitespaces).isEmpty {
            return note.title
        }
        let lines = note.content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.isEmpty ? "Neue Notiz" : lines[0]
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.fromName(note.color))
                .frame(width: 8, height: 8)
            
            Text(displayTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(displayTitle == "Neue Notiz" ? .secondary : .primary)
                .lineLimit(1)
            
            Spacer()
            
            Text(relativeTime(from: note.updatedAt))
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            
            Button(action: copyToClipboard) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .foregroundColor(copied ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 16)
        }
        .padding(10)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func copyToClipboard() {
        let fullText = note.title.isEmpty ? note.content : "\(note.title)\n\(note.content)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fullText, forType: .string)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = false }
        }
    }
    
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
