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

struct ContactData: Identifiable {
    let id = UUID()
    let avatarData: AvatarInput
    let displayName: String
    let contact: MXKContact
}

@available(iOS 15.0, *)
struct CloudShareView: View {
    @Environment(\.dismiss) var dismiss
    @State private var roomsData: [RoomData] = []
    @State private var contactsData: [ContactData] = []
    @State private var session: MXSession?
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    @State private var showContacts = false
    @State private var selectedImage = UIImage()
    @State private var selectedURL: URL?
    @State private var uploadProgress: Double = 0.0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            if selectedURL != nil || !selectedImage.isEqual(UIImage()) {
                if (uploadProgress != 0) {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal)
                        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                }

                Text("Список \(showContacts ? "контактов" : "чатов")")
                    .font(.title)
                    .bold()
                    .padding(.top, 16)
                    .padding(.horizontal)
                
                Toggle("Показать контакты", isOn: $showContacts)
                    .padding(.horizontal)

                if showContacts {
                    List(contactsData) { contact in
                        Button(action: {
                            Task {
                                await onContactTap(contactData: contact)
                            }
                        }) {
                            HStack {
                                if (session != nil) {
                                    AvatarImage(avatarData: contact.avatarData, size: .small)
                                }
                                
                                Text(contact.displayName)
                                    .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: session!.mediaManager)))
                            .padding(.vertical, 6)
                        }
                    }
                    .onAppear(perform: setContacts)
                }
                else {
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
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: session!.mediaManager)))
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            else {
                Text("Отправка файла в облако")
                    .font(.title)
                    .bold()
                    .padding(.top, 16)
                Spacer()
                VStack (alignment: .center){
                    Text("Отправить:")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)

                    Button(action: {
                        showImagePicker = true
                    }){
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Из галереи")
                        }
                    }
                    .padding(.vertical, 6)
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(sourceType: .photoLibrary, selectedImage: self.$selectedImage)
                    }
                    
                    Button(action: {
                        showDocumentPicker = true
                    }){
                        HStack {
                            Image(systemName: "arrow.up.doc")
                            Text("Из файлов")
                        }
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
    
    private var progressView: some View {
        if uploadProgress > 0 && uploadProgress < 1 {
            return AnyView(ProgressView(value: uploadProgress))
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private func onContactTap(contactData: ContactData) async {
        guard let recipientID: String = contactData.contact.matrixIdentifiers[0] as? String else {
            return
        }
        
        await sendAttachmentToUser(recipientID: recipientID)
    }
    
    private func onRoomTap(roomData: RoomData) async {
        print("Нажата комната:", roomData.displayName)
        
        guard let userId = session?.myUser?.userId,
              var members: [MXRoomMember] = try? await roomData.room.members()?.joinedMembers
        else {
            return
        }
        
        members.removeAll { $0.userId == userId }
        
        for member in members {
            await sendAttachmentToUser(recipientID: member.userId)
        }
    }
    
    private func sendAttachmentToUser (recipientID: String) async {
        guard let senderName = session?.myUser?.displayName else {
            return
        }

        if selectedURL != nil {
            await uploadFileToFirebaseStorage(fileURL: selectedURL!, recipientID: recipientID, senderName: senderName)
        }
        else if !selectedImage.isEqual(UIImage()) {
            await uploadImageToFirebaseStorage(image: selectedImage, recipientID: recipientID, senderName: senderName)
        }
    }
    
    private func setRooms() {
        let mainSession = AppDelegate.theDelegate().mxSessions.first as? MXSession
        session = mainSession
        
        if let rooms = mainSession?.rooms {
            roomsData = rooms.map {
                RoomData(avatarData: $0.avatarData, displayName: $0.displayName ?? "Unknown", room: $0)
            }
        }
    }
    
    private func setContacts () {
        guard var contacts: [MXKContact] = MXKContactManager.shared().matrixContacts as? [MXKContact] else {
            return
        }
        
        if let userId = session?.myUser?.userId {
            contacts.removeAll { $0.matrixIdentifiers[0] as! String == userId }
        }

        contactsData = contacts.map {
            let avatarData = AvatarInput(mxContentUri: nil, matrixItemId: "", displayName: $0.displayName)
            return ContactData(avatarData: avatarData, displayName: $0.displayName, contact: $0)
        }
    }
    
    private func createFirestoreCloudDocument(filePath: String, recipientID: String, senderName: String) {
        let defaultFirestore = Firestore.firestore()
        
        let data: [String: Any] = [
            "filePath": filePath,
            "recipientID": recipientID,
            "senderName": senderName,
            "status": "Pending",
            "createdAt": FieldValue.serverTimestamp()
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
            dismiss()
        }
    }
    
    private func uploadImageToFirebaseStorage(imageData: Data, recipientID: String, senderName: String) async {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let fileName = UUID().uuidString
        let filePath = "files/\(recipientID)/pending/\(fileName).jpg"
        let fileRef = storageRef.child(filePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = fileRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
            } else {
                print("Image uploaded successfully!")
                createFirestoreCloudDocument(filePath: filePath, recipientID: recipientID, senderName: senderName)
            }
        }
        
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
        }
        
        do {
            _ = try await uploadTask.resume()
        } catch {
            print("Error uploading image: \(error)")
        }
    }
    
    private func uploadImageToFirebaseStorage(image: UIImage, recipientID: String, senderName: String) async {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            await uploadImageToFirebaseStorage(imageData: imageData, recipientID: recipientID, senderName: senderName)
        } else {
            print("TEST Failed to convert image to data")
        }
    }
    
    private func uploadFileToFirebaseStorage(fileURL: URL, recipientID: String, senderName: String) async {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let fileName = UUID().uuidString
        let fileExtension = fileURL.pathExtension
        let filePath = "files/\(recipientID)/pending/\(fileName).\(fileExtension)"
        let fileRef = storageRef.child(filePath)
        
        let contentType = "image/\(fileExtension)"
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        
        let uploadTask = fileRef.putFile(from: fileURL, metadata: metadata) { metadata, error in
            if let error = error {
                print("TEST Error uploading file: \(error.localizedDescription)")
            } else {
                print("TEST File uploaded successfully!")
                createFirestoreCloudDocument(filePath: filePath, recipientID: recipientID, senderName: senderName)
            }
        }
        
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
        }
        
        do {
            _ = try await uploadTask.resume()
        } catch {
            print("TEST Error uploading file: \(error)")
        }
    }
}
