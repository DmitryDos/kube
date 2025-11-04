import SwiftUI

struct ExpandableSearchBar: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void
    let onClear: (() -> Void)?
    
    @State private var isExpanded: Bool = false
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
        HStack(spacing: 0) {
            if isExpanded {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeObserver.themedPrimaryColor)
                        .frame(width: 20, height: 20)
                    
                    TextField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(themeObserver.themedPrimaryColor)
                        .focused($isFocused)
                        .onSubmit {
                            onSubmit()
                        }
                        .onChange(of: text) { newValue in
                            if newValue.isEmpty, let onClear = onClear {
                                onClear()
                            }
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
                .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeObserver.themedAccentColor)
                        .frame(width: 30, height: 30)
                        .background(themeObserver.contrastColor)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
        .onChange(of: isFocused) { focused in
            if !focused && text.isEmpty {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded = false
                }
            }
        }
    }
}
