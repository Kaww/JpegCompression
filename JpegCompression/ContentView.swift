import SwiftUI
import Photos

import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {

    @Environment(\.presentationMode) var presentationMode

    var onImagePicked: (UIImage) -> Void
    var source: UIImagePickerController.SourceType

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = source
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let  parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.onImagePicked(uiImage)
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ContentView: View {
    @State private var showImagePicker = false

    @State private var sourceImage: UIImage?
    @State private var compressedImage: UIImage?

    @State var sourceImageView: Image?
    @State var compressedImageView: Image?

    @State private var compressionQuality: Double = 1

    var body: some View {
        ScrollView {
            VStack {
                Button("PICK IMAGE") { openImagePicker() }

                if let sourceImageView = sourceImageView {
                    Text("Source UIImage from picker")
                    sourceImageView
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .frame(width: UIScreen.main.bounds.width - 20)
                }

                if let compressedImageView = compressedImageView {
                    Text("Image made from sourceImage's jpegData with a compressionQuality of \(String(format: "%.2f", compressionQuality))")
                    compressedImageView
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .frame(width: UIScreen.main.bounds.width - 20)
                }

                if compressedImageView != nil {
                    Slider(value: $compressionQuality, in: 0...1, step: 0.01)
                        .padding(.horizontal, 20)

                    Button("SAVE COMPRESSED IMAGE") {
                        if let compressedImage = compressedImage {
                            UIImageWriteToSavedPhotosAlbum(compressedImage, nil, nil, nil)
                        }
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(onImagePicked: loadImages, source: .photoLibrary)
                    .edgesIgnoringSafeArea([.horizontal, .bottom])
            }
            .onChange(of: sourceImage) { _ in updateImages() }
            .onChange(of: compressionQuality) { amount in updateImages(compression: amount) }
        }
    }

    private func openImagePicker() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access not allowed by user.")
                return
            }

            showImagePicker = true
        }
    }

    private func loadImages(from uiImage: UIImage) {
        self.sourceImage = uiImage
    }

    private func updateImages(compression: Double = 1.0) {
        guard let sourceImage = sourceImage else { return }
        sourceImageView = Image(uiImage: sourceImage)

        guard
            let sourceImageData = sourceImage.jpegData(compressionQuality: compression),
            let compressedUIImage = UIImage(data: sourceImageData)
        else {
            compressedImage = nil
            return
        }
        compressedImage = compressedUIImage
        compressedImageView = Image(uiImage: compressedUIImage)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
