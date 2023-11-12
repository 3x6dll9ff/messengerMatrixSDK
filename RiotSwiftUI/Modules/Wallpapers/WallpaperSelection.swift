// 
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import UIKit

struct WallpaperSelection: View {
    @State var sw = UserDefaults.standard.string(forKey: "storedBg")
    @Environment(\.presentationMode) var presentationMode
    let w = UIScreen.main.bounds.width
    let h = UIScreen.main.bounds.height
    @State private var selectedBg = "bgChatImg"
    @State private var goTry = false
    
    var body: some View {
        VStack{
            Spacer()
                .frame(height: h/20)
            
            wallpapers
            NavigationLink("", destination: WallpaperTryView(bg: selectedBg), isActive: $goTry)
            
            HStack{
                Text("Сhoose a theme or create your own")
                  .font(Font.custom("Inter", size: 10))
                  .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.51))
                Spacer()
            }
            .frame(width: w*0.92)
            
            Button(action: {
                goTry = true
                UserDefaults.standard.set(selectedBg, forKey: "storedBg")
            }){
                HStack{
                    Text("Try")
                      .font(
                        Font.custom("Inter", size: 13)
                          .weight(.medium)
                      )
                      .padding(.horizontal)
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .padding(.horizontal)
                }
                .frame(width: w*0.92, height: 45)
                .background(Color(red: 0.06, green: 0.06, blue: 0.06))
                .cornerRadius(10)
                .padding(.vertical)
            }
            
            Spacer()
        }
        .onAppear{
            print("Saved String: \(sw ?? "DEFAULT")")
        }
        .navigationTitle("Wallpapers")
        .frame(width: w)
        .background(Color(red: 0.12, green: 0.13, blue: 0.14))
    }
    
    //Select Image as wallpaper from gallery
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented: Bool = false
    
    var wallpapers: some View{
        VStack{
            HStack{
                Button(action: {
                    isImagePickerPresented.toggle()
                }){
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .frame(width: w*0.27, height: h*0.18)
                            .background(Color(red: 0.12, green: 0.13, blue: 0.14))
                            .cornerRadius(10)
                    } else {
                        Image(systemName: "camera")
                            .frame(width: w*0.27, height: h*0.18)
                            .background(Color(red: 0.12, green: 0.13, blue: 0.14))
                            .cornerRadius(10)
                    }
                }
                .sheet(isPresented: $isImagePickerPresented, onDismiss: saveImage) {
                    MyImagePicker(selectedImage: $selectedImage)
                }
                
                Button(action: {
                    selectedBg = "bgChatImg"
                }){
                    Image("bgChatImg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w*0.27, height: h*0.18)
                        .cornerRadius(10)
                }
                Button(action: {
                    selectedBg = "wallpaper2"
                }){
                    Image("wallpaper2")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w*0.27, height: h*0.18)
                        .cornerRadius(10)
                }
            }
            HStack{
                Button(action: {
                    selectedBg = "wallpaper1"
                }){
                    Image("wallpaper1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w*0.27, height: h*0.18)
                        .cornerRadius(10)
                }
                Button(action: {
                    selectedBg = "wallpaper3"
                }){
                    Image("wallpaper3")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w*0.27, height: h*0.18)
                        .cornerRadius(10)
                }
                Button(action: {
                    selectedBg = "wallpaper4"
                }){
                    Image("wallpaper4")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w*0.27, height: h*0.18)
                        .cornerRadius(10)
                }
            }
            HStack{
                Button(action: {
                    selectedBg = "wallpaper5"
                }){
                    Image("wallpaper5")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w*0.27, height: h*0.18)
                        .cornerRadius(10)
                }
                Button(action: {
                    selectedBg = "wallpaper6"
                }){
                    Image("wallpaper6")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w*0.27, height: h*0.18)
                        .cornerRadius(10)
                }
                Button(action: {
                    selectedBg = "wallpaper7"
                }){
                    Image("wallpaper7")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w*0.27, height: h*0.18)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
        .cornerRadius(10)
    }
    
    func saveImage() {
        guard let selectedImage = selectedImage else { return }
        // Perform any image-related processing if needed
        
        // Save the image to the file system
        if let data = selectedImage.jpegData(compressionQuality: 1.0) {
            let fileName = "selectedImage.jpg"
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
            try? data.write(to: fileURL)
            
            // Save the file URL to UserDefaults
            UserDefaults.standard.set(fileURL, forKey: "selectedImageURL")
            selectedBg = "selectedImageURL"
            print("selectedImageURL: \(fileURL)")
        }
    }
}

struct MyImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: MyImagePicker
        
        init(parent: MyImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            picker.dismiss(animated: true, completion: nil)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update UI if needed
    }
}

#Preview {
    WallpaperSelection()
}
