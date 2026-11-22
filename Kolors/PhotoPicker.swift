import SwiftUI

enum PhotoSource: Identifiable {
    case camera, library

    static var isCameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var id: Self { self }

    var sourceType: UIImagePickerController.SourceType { self == .camera ? .camera : .photoLibrary }
}

extension View {
    /// Presents the camera or photo library, and reports the photo once the picker has closed.
    func photoPicker(source: Binding<PhotoSource?>, onPick: @escaping (UIImage) -> Void) -> some View {
        modifier(PhotoPickerModifier(source: source, onPick: onPick))
    }
}

private struct PhotoPickerModifier: ViewModifier {
    @Binding var source: PhotoSource?
    let onPick: (UIImage) -> Void

    @State private var picked: UIImage?

    func body(content: Content) -> some View {
        // Must be modal: pushed onto the navigation stack, the picker never closes.
        content.fullScreenCover(item: $source, onDismiss: report) { source in
            ImagePickerView(sourceType: source.sourceType) { picked = $0 }
                .ignoresSafeArea()
        }
    }

    private func report() {
        guard let image = picked else { return }
        picked = nil
        onPick(image)
    }
}
