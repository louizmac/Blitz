import SwiftUI

struct EditView: View {
    @EnvironmentObject var store: NoteStore
    @Binding var note: Note
    var onBack: () -> Void
    
    let colors = ["yellow", "red", "blue", "green", "orange", "purple"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(colors, id: \.self) { colorName in
                        Circle()
                            .fill(Color.fromName(colorName))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: note.color == colorName ? 2 : 0)
                                    .padding(-2)
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    note.color = colorName
                                }
                            }
                    }
                    
                    Button(action: {
                        withAnimation {
                            store.notes.removeAll { $0.id == note.id }
                            onBack()
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 4)
            
            TextField("Titel eingeben...", text: $note.title)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Divider().opacity(0.3)
            
            ZStack(alignment: .topLeading) {
                if note.content.isEmpty {
                    Text("Gedanken ablegen…")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                
                InteractiveTextEditor(text: Binding(
                    get: { note.content },
                    set: { newText in
                        note.content = newText
                        note.updatedAt = Date()
                    }
                ))
            }
        }
    }
}
