// swiftlint:disable all

import SwiftUI
import DesignKit
import FirebaseFirestore
import FirebaseStorage

struct RoomData: Identifiable {
    let id = UUID()
    let avatarData: AvatarInput
    let displayName: String
    let room: MXRoom
}

@available(iOS 15.0, *)
struct CloudShareView: View {
    @State private var roomsData: [RoomData] = []
    @State private var session: MXSession?
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    @State private var selectedImage = UIImage()
    @State private var selectedURL: URL?

    var body: some View {
        VStack (alignment: .leading) {
            if selectedURL != nil || !selectedImage.isEqual(UIImage()) {
                Text("Список чатов")
                    .font(.title)
                    .bold()
                    .padding(.top, 16)
                    .padding(.horizontal)
                List(roomsData) { room in
                    Button(action: {
                        Task {
                            await onRoomTap(roomData: room)
                        }
                    }) {
                        HStack {
                            if (session != nil) {
                                AvatarImage(avatarData: room.avatarData, size: .small)
                            }
                            
                            Text(room.displayName)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: session!.mediaManager)))
                        .padding(.vertical, 6)
                    }
                }
            }
            else {
                Text("Отправка файла в облако")
                    .font(.title)
                    .bold()
                    .padding(.top, 16)
                Text("Отправить из:")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.gray)
                VStack {
                    Button(action: {
                        showImagePicker = true
                    }){
                        Text("Галереи")
                    }
                    .padding(.vertical, 6)
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(sourceType: .photoLibrary, selectedImage: self.$selectedImage)
                    }
                    
                    Button(action: {
                        showDocumentPicker = true
                    }){
                        Text("Файлов")
                    }
                    .padding(.vertical, 6)
                    .sheet(isPresented: $showDocumentPicker) {
                        DocumentPicker(selectedURL: $selectedURL)
                    }
                }
                Spacer()
            }
        }
        .onAppear(perform: setRooms)
        .navigationTitle("Все чаты")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func onRoomTap (roomData: RoomData) async {
        print("Нажата комната:", roomData.displayName)
        
        
        guard let userId = session?.myUser?.userId,
              let senderName = session?.myUser?.displayName,
              var members: [MXRoomMember] = try? await roomData.room.members()?.joinedMembers
        else {
            return
        }
        
        members.removeAll { $0.userId == userId }
        
        if selectedURL != nil {
            for member in members {
                uploadFileToFirebaseStorage(fileURL: selectedURL!, recipientID: member.userId, senderName: senderName)
            }
        }
        else if !selectedImage.isEqual(UIImage()) {
            for member in members {
                uploadImageToFirebaseStorage(image: selectedImage, recipientID: member.userId, senderName: senderName)
            }
        }
    }
    
    func setRooms () {
        let mainSession = AppDelegate.theDelegate().mxSessions.first as? MXSession
        session = mainSession
        
        if let rooms = mainSession?.rooms {
            roomsData = rooms.map {
                RoomData(avatarData: $0.avatarData, displayName: $0.displayName ?? "Unknown", room: $0)
            }
        }
    }
    
    func createFirestoreCloudDocument(filePath: String, recipientID: String, senderName: String) {
        let defaultFirestore = Firestore.firestore()
        
        let data: [String: Any] = [
            "filePath": filePath,
            "recipientID": recipientID,
            "senderName": senderName
        ]
        
        let ref: DocumentReference? = defaultFirestore.collection("cloud").addDocument(data: data) { error in
            if let error = error {
                print("TEST Error adding document: \(error)")
            } else {
                print("TEST Document added successfully!")
            }
        }
        
        if let documentID = ref?.documentID {
            print("TEST Document ID: \(documentID)")
        }
    }
    
    func uploadImageToFirebaseStorage(imageData: Data, recipientID: String, senderName: String) {
        // Create a reference to Firebase Storage
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // Generate a unique file name with the ".jpg" extension
        let fileName = UUID().uuidString
        let filePath = "files/\(recipientID)/pending/\(fileName).jpg"
        
        // Create a path to the file in Storage
        let fileRef = storageRef.child(filePath)
        
        // Create metadata to specify the MIME type
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload the image data to Storage with the specified metadata
        let uploadTask = fileRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                // Handle upload error
                print("Error uploading image: \(error.localizedDescription)")
            } else {
                // Upload successful
                print("Image uploaded successfully!")
                self.createFirestoreCloudDocument(filePath: filePath, recipientID: recipientID, senderName: senderName)
            }
        }
    }

    func uploadImageToFirebaseStorage(image: UIImage, recipientID: String, senderName: String) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            // Call the original uploadImageToFirebaseStorage function with the image data
            uploadImageToFirebaseStorage(imageData: imageData, recipientID: recipientID, senderName: senderName)
        } else {
            print("TEST Failed to convert image to data")
        }
    }

    func uploadFileToFirebaseStorage(fileURL: URL, recipientID: String, senderName: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let fileName = UUID().uuidString
        let fileExtension = fileURL.pathExtension
        let filePath = "files/\(recipientID)/pending/\(fileName).\(fileExtension)"
        
        let fileRef = storageRef.child(filePath)
        
        let contentType = "image/\(fileExtension)" // Default content type is "image/*"
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        
        let uploadTask = fileRef.putFile(from: fileURL, metadata: metadata) { metadata, error in
            if let error = error {
                // Handle upload error
                print("TEST Error uploading file: \(error.localizedDescription)")
            } else {
                // Upload successful
                print("TEST File uploaded successfully!")
                self.createFirestoreCloudDocument(filePath: filePath, recipientID: recipientID, senderName: senderName)
            }
        }
    }


}
