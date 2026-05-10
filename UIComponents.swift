import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}

extension Color {
    static func fromName(_ name: String) -> Color {
        switch name {
        case "yellow": return .yellow
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .yellow
        }
    }
}

struct InteractiveTextEditor: NSViewRepresentable {
    @Binding var text: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor.textColor
        textView.insertionPointColor = NSColor.textColor
        textView.string = text
        textView.allowsUndo = true
        textView.isRichText = false
        
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
            textView.setSelectedRange(NSRange(location: textView.string.count, length: 0))
        }
        
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        clickGesture.numberOfClicksRequired = 1
        textView.addGestureRecognizer(clickGesture)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            
            if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
            } else {
                textView.setSelectedRange(NSRange(location: text.count, length: 0))
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: InteractiveTextEditor
        
        init(_ parent: InteractiveTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
        
        @objc func handleTap(_ gesture: NSClickGestureRecognizer) {
            guard let textView = gesture.view as? NSTextView else { return }
            let location = gesture.location(in: textView)
            let charIndex = textView.characterIndexForInsertion(at: location)
            
            let nsString = textView.string as NSString
            
            guard charIndex < nsString.length else { return }
            
            let lineRange = nsString.lineRange(for: NSRange(location: charIndex, length: 0))
            let lineString = nsString.substring(with: lineRange)
            
            if let boxRange = lineString.range(of: "[ ]"),
               isClickInsideRange(charIndex: charIndex, lineRange: lineRange, matchRange: boxRange, in: lineString) {
                let targetRange = NSRange(location: lineRange.location + boxRange.lowerBound.utf16Offset(in: lineString), length: 3)
                textView.insertText("[x]", replacementRange: targetRange)
            }
            else if let checkedRange = lineString.range(of: "[x]"),
                    isClickInsideRange(charIndex: charIndex, lineRange: lineRange, matchRange: checkedRange, in: lineString) {
                let targetRange = NSRange(location: lineRange.location + checkedRange.lowerBound.utf16Offset(in: lineString), length: 3)
                textView.insertText("[ ]", replacementRange: targetRange)
            }
        }
        
        private func isClickInsideRange(charIndex: Int, lineRange: NSRange, matchRange: Range<String.Index>, in string: String) -> Bool {
            let start = lineRange.location + matchRange.lowerBound.utf16Offset(in: string)
            let end = lineRange.location + matchRange.upperBound.utf16Offset(in: string)
            return charIndex >= start && charIndex <= end
        }
    }
}
