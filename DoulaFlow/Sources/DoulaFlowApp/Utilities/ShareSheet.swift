#if canImport(UIKit)
import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
import SwiftUI

/// Fallback implementation to allow building the package on non-UIKit platforms (e.g. macOS).
struct ShareSheet: View {
    var activityItems: [Any]

    var body: some View {
        Text("Sharing is not available on this platform.")
            .padding()
    }
}
#endif
