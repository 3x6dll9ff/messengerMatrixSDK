// swiftlint:disable all

import SwiftUI
import FirebaseStorage

let storageUrl = "gs://bigstarconnect.appspot.com"

struct CloudListView: View {
    @State private var fileList: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(VectorL10n.myFilesTitle)
                    .font(.title)
                    .bold()
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(fileList, id: \.self) { file in
                        FileView(file: file) {
                            deleteFile(file)
                        }
                    }
                }
                .padding()
                .onAppear {
                    fetchFileList()
                }
            }
        }
    }

    private func fetchFileList() {
        let storage = Storage.storage(url: storageUrl)
        let storageRef = storage.reference()

        let filesRef = storageRef.child("files")

        filesRef.listAll { (result, error) in
            if let error = error {
                print("Error fetching file list: \(error.localizedDescription)")
                return
            }

            fileList = result!.items.map { $0.name }
        }
    }

    private func deleteFile(_ file: String) {
        let storage = Storage.storage(url: storageUrl)
        let storageRef = storage.reference()

        // Get a reference to the file in Firebase Cloud Storage
        let fileRef = storageRef.child("files/\(file)")

        // Delete the file
        fileRef.delete { error in
            if let error = error {
                print("Error deleting file: \(error.localizedDescription)")
                return
            }

            print("File deleted: \(file)")

            fileList.removeAll { $0 == file }
        }
    }
}

struct FileView: View {
    let file: String
    @State private var image: Image? = nil
    @State private var showMenu: Bool = false
    let onDelete: () -> Void

    var body: some View {
        VStack {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100, maxHeight: 100)
            } else {
                Image(systemName: "doc")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 50, maxHeight: 50)
            }
            Text(file)
                .font(.subheadline)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)
        }
        .onAppear {
            loadImage()
        }
        .onTapGesture {
            showMenu = true
        }
        .actionSheet(isPresented: $showMenu) {
            ActionSheet(title: Text(file), buttons: [
                .default(Text(VectorL10n.download), action: {
                    downloadFile()
                }),
                .destructive(Text(VectorL10n.delete), action: {
                    onDelete()
                }),
                .cancel()
            ])
        }
    }

    private func loadImage() {
        let storage = Storage.storage(url: storageUrl)
        let storageRef = storage.reference()

        let fileRef = storageRef.child("files/\(file)")

        fileRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error downloading file: \(error.localizedDescription)")
                return
            }

            guard let imageData = data, let uiImage = UIImage(data: imageData) else {
                print("Error converting data to image")
                return
            }

            self.image = Image(uiImage: uiImage)
        }
    }

    private func downloadFile() {
        let storage = Storage.storage(url: storageUrl)
        let storageRef = storage.reference()

        let fileRef = storageRef.child("files/\(file)")

        // Create a temporary file URL to store the downloaded file
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(file)

        let downloadTask = fileRef.write(toFile: tempFileURL)

        // Create a progress view to show the download progress
        let progressView = UIProgressView(progressViewStyle: .default)
           progressView.translatesAutoresizingMaskIntoConstraints = false

        // Create an alert controller to show the progress view
        let alertController = UIAlertController(title: VectorL10n.downloading, message: nil, preferredStyle: .alert)
        alertController.view.addSubview(progressView)

        // Add constraints for the progress view
        progressView.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 16).isActive = true
        progressView.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor, constant: -16).isActive = true
        progressView.bottomAnchor.constraint(equalTo: alertController.view.bottomAnchor, constant: -16).isActive = true

        // Find the topmost view controller to present the alert controller
        guard let topViewController = UIApplication.shared.windows.first?.rootViewController?.topmostViewController() else {
            return
        }

        // Present the alert controller
        topViewController.present(alertController, animated: true, completion: nil)

        // Observe the progress of the download task
        let observer = downloadTask.observe(.progress) { snapshot in
            // Update the progress view based on the download progress
            let progress = Float(snapshot.progress?.fractionCompleted ?? 0)
            progressView.setProgress(progress, animated: true)
        }

        // Start the download task
        downloadTask.observe(.success) { snapshot in
            // Remove the observer
            downloadTask.removeObserver(withHandle: observer)

            // Dismiss the progress alert controller on the main queue
            DispatchQueue.main.async {
                alertController.dismiss(animated: true) {
                    // Create a UIActivityViewController to share or save the file
                    let activityViewController = UIActivityViewController(activityItems: [tempFileURL], applicationActivities: nil)

                    // Find the topmost view controller to present the activity view controller
                    if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topmostViewController() {
                        topViewController.present(activityViewController, animated: true, completion: nil)
                    }
                }
            }
        }

        downloadTask.observe(.failure) { snapshot in
            // Remove the observer
            downloadTask.removeObserver(withHandle: observer)

            // Dismiss the progress alert controller on the main queue
            DispatchQueue.main.async {
                alertController.dismiss(animated: true) {
                    if let error = snapshot.error as NSError? {
                        print("Error downloading file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

}

extension UIViewController {
    func topmostViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topmostViewController()
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topmostViewController() ?? self
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topmostViewController() ?? self
        }
        return self
    }
}
