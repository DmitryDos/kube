import SwiftUI

struct ExpandableSearchBar: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void
    let onClear: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String,
        onSubmit: @escaping () -> Void = {},
        onClear: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
        self.onClear = onClear
    }
    
    var body: some View {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeObserver.themedPrimaryColor)
                        .frame(width: 20, height: 20)
                    
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.6))
                }
                TextField("", text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(themeObserver.themedPrimaryColor)
            }
                        .focused($isFocused)
                        .onSubmit {
                            onSubmit()
                        }
                    
                    if !text.isEmpty {
                        Button {
                            text = ""
                            onClear?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.6))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeObserver.contrastColor)
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
    }
}
