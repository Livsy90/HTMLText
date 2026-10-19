# HTMLText

A lightweight SwiftUI view for displaying simple HTML content as styled text.

`HTMLText` converts HTML into an attributed string and renders it using native SwiftUI `Text`, with support for links, basic HTML formatting, and customizable link appearance.

## Usage

```swift
import SwiftUI

HTMLText("""
By using this <b>app</b>, you agree to our
<a href="https://example.com/privacy">Privacy Policy</a>
and
<a href="https://example.com/terms">Terms of Service</a>.
""")
```

Links are opened using `UIApplication.shared.open` by default.

You can provide custom link handling:

```swift
HTMLText(html) { url in
    print("Open:", url)
}
```

## Styling

```swift
HTMLText(html)
    .font(.systemFont(ofSize: 18))
    .linkColor(.purple)
    .boldLinks(true)
    .underlinedLinks(true)
```

Available modifiers:

- `.font(_:)` — sets the base font
- `.linkColor(_:)` — sets the link color
- `.boldLinks(_:)` — controls whether links are bold
- `.underlinedLinks(_:)` — controls link underlining

## Requirements

- iOS 15+
- SwiftUI

## License

MIT
