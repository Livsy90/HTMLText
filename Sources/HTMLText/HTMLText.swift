import SwiftUI

/// A SwiftUI view that renders a subset of HTML as styled text.
///
/// `HTMLText` converts an HTML string into an `NSAttributedString`, applies
/// configurable styling (font, link color, underline, and bold for links), and
/// displays it in a `Text` view. Tapping on links triggers a configurable
/// callback so the host can decide how to open URLs.
///
/// - Note: You can customize link behavior by providing the `onLinkTap` closure
///   in the initializer, or by using the provided modifiers to control
///   appearance.
public struct HTMLText: View {
    
    @StateObject private var store = HTMLStore()
    
    private let html: String
    private let onLinkTap: (URL) -> Void
    private var font: UIFont = .systemFont(ofSize: 17)
    private var underlinedLinks: Bool = false
    private var linkColor: UIColor = .blue
    private var boldLinks: Bool = true
    
    /// Creates a new HTMLText view.
    ///
    /// - Parameters:
    ///   - html: The raw HTML string to render.
    ///   - onLinkTap: A closure invoked when the user taps a link contained in
    ///     the HTML. The default implementation opens the URL via
    ///     `UIApplication.shared.open(_:)`.
    public init(
        _ html: String,
        onLinkTap: @escaping (URL) -> Void = { url in UIApplication.shared.open(url) }
    ) {
        self.html = html
        self.onLinkTap = onLinkTap
    }
    
    public var body: some View {
        Text(AttributedString(store.htmlText))
            .environment(\.openURL, OpenURLAction { url in
                onLinkTap(url)
                return .handled
            })
            .onAppear {
                store.configure(
                    html: html,
                    font: font,
                    underlinedLinks: underlinedLinks,
                    linkColor: linkColor,
                    boldLinks: boldLinks
                )
            }
    }
}

public extension HTMLText {
    /// Sets the base font applied to the rendered HTML.
    ///
    /// The family and point size are propagated to the HTML content while
    /// preserving symbolic traits (e.g., italic, bold) where applicable.
    ///
    /// - Parameter font: The font to apply. Default is system font at 17pt.
    /// - Returns: A modified `HTMLText` with the given font.
    func font(_ font: UIFont) -> HTMLText {
        var view = self
        view.font = font
        return view
    }
    
    /// Controls whether detected links are underlined.
    ///
    /// - Parameter underlinedLinks: Pass `true` to underline links; `false` to
    ///   remove the underline. Default is `false`.
    /// - Returns: A modified `HTMLText` with the specified underline behavior.
    func underlinedLinks(_ underlinedLinks: Bool) -> HTMLText {
        var view = self
        view.underlinedLinks = underlinedLinks
        return view
    }
    
    /// Controls whether detected links are displayed in a bold font weight.
    ///
    /// - Parameter boldLinks: Pass `true` to render links in bold; `false` to
    ///   keep the base font weight. Default is `true`.
    /// - Returns: A modified `HTMLText` with the specified bold behavior.
    func boldLinks(_ boldLinks: Bool) -> HTMLText {
        var view = self
        view.boldLinks = boldLinks
        return view
    }
    
    /// Sets the foreground color used for detected links.
    ///
    /// - Parameter linkColor: The color to apply to links. Default is `.blue`.
    /// - Returns: A modified `HTMLText` with the specified link color.
    func linkColor(_ linkColor: UIColor) -> HTMLText {
        var view = self
        view.linkColor = linkColor
        return view
    }
}

private final class HTMLStore: ObservableObject {
    
    @Published var htmlText: NSAttributedString = .init()
    private var isConfigured: Bool = false
    
    func configure(
        html: String,
        font: UIFont,
        underlinedLinks: Bool = false,
        linkColor: UIColor = .blue,
        boldLinks: Bool = true
    ) {
        guard !isConfigured else { return }
        isConfigured.toggle()
        
        htmlText = html.htmlToAttributedString(
            font: font,
            underlinedLinks: underlinedLinks,
            linkColor: linkColor,
            boldLinks: boldLinks
        )
    }
}

private extension String {
    func htmlToAttributedString(
        font: UIFont,
        underlinedLinks: Bool,
        linkColor: UIColor,
        boldLinks: Bool
    ) -> NSAttributedString {
        guard
            let data = self.data(using: .utf8),
            let attributedString = try? NSMutableAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            ) else {
            return .init()
        }
        
        attributedString.setFontFace(
            font: font
        )
        attributedString.decorateLinks(
            linkColor: linkColor,
            isUnderlined: underlinedLinks,
            isBold: boldLinks,
            font: font
        )
        
        return attributedString
    }
}

private extension NSMutableAttributedString {
    func decorateLinks(
        linkColor: UIColor,
        isUnderlined: Bool,
        isBold: Bool,
        font: UIFont
    ) {
        enumerateAttribute(
            .link,
            in: NSRange(location: .zero, length: self.length),
            options: []
        ) { value, range, _ in
            if value != nil {
                var attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: linkColor
                ]
                
                if !isUnderlined {
                    attributes[.underlineStyle] = NSUnderlineStyle().rawValue
                }
                
                if isBold {
                    let boldFont = UIFont(
                        descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor,
                        size: font.pointSize
                    )
                    attributes[.font] = boldFont
                }
                
                addAttributes(attributes, range: range)
            }
        }
    }
    
    func setFontFace(
        font: UIFont,
        color: UIColor? = nil
    ) {
        enumerateAttribute(
            .font,
            in: NSRange(location: .zero, length: self.length)
        ) { value, range, _ in
            if let fontValue = value as? UIFont,
               let newFontDescriptor = fontValue
                .fontDescriptor
                .withFamily(font.familyName)
                .withSymbolicTraits(fontValue.fontDescriptor.symbolicTraits) {
                let newFont = UIFont(
                    descriptor: newFontDescriptor,
                    size: font.pointSize
                )
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
                if let color {
                    removeAttribute(
                        .foregroundColor,
                        range: range
                    )
                    addAttribute(
                        .foregroundColor,
                        value: color,
                        range: range
                    )
                }
            }
        }
    }
}

/// Preview demonstrating custom font size, link color, and link styling.
#Preview {
    HTMLText("By using this <b>app</b>, you agree to our <a href='https://example.com/privacy'>Privacy Policy</a> and <a href='https://example.com/terms'>Terms of Service</a>.")
    .font(.systemFont(ofSize: 22))
    .linkColor(.purple)
    .boldLinks(true)
    .underlinedLinks(true)
}
