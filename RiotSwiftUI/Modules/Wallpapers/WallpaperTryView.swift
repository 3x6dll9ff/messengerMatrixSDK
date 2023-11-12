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

struct WallpaperTryView: View {
    @Environment(\.presentationMode) var presentationMode
    let w = UIScreen.main.bounds.width
    let h = UIScreen.main.bounds.height
    let bg: String
    let url = UserDefaults.standard.url(forKey: "selectedImageURL")
    
    var body: some View {
        ZStack{
            if bg != "selectedImageURL"{
                Image(bg)
                    .resizable()
                    .onAppear{
                        UserDefaults.standard.removeObject(forKey: "gallery")
                    }
            }else{
                Image(uiImage: loadData())
                    .resizable()
                    .onAppear{
                        UserDefaults.standard.set("gallery", forKey: "gallery")
                    }
            }
            
            VStack{
                Spacer()
                HStack{
                    Text("Hello! welcome to Bigstar messenger. To get started, go to the settings and check it out! There is no need to reply to this message.")
                        .font(Font.custom("Inter", size: 15))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.53, green: 0.44, blue: 0.77))
                        .cornerRadius(20)
                        .padding(.leading, 10)
                    Spacer()
                }
                HStack{
                    Spacer()
                    Text("Прив")
                        .font(Font.custom("Inter", size: 15))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.53, green: 0.44, blue: 0.77))
                        .cornerRadius(20)
                        .padding(.leading, 10)
                }
                HStack{
                    Text("Не отвечай, тупой.")
                        .font(Font.custom("Inter", size: 15))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.53, green: 0.44, blue: 0.77))
                        .cornerRadius(20)
                        .padding(.leading, 10)
                    Spacer()
                }
                HStack{
                    Spacer()
                    Text("Сам тупой")
                        .font(Font.custom("Inter", size: 15))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.53, green: 0.44, blue: 0.77))
                        .cornerRadius(20)
                        .padding(.leading, 10)
                }
                Spacer().frame(height: w*0.25)
            }
            
            VStack{
                HStack{
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }){
                        HStack{
                            Image(systemName: "chevron.left")
                                .padding(.horizontal, 3)
                            Text("Back")
                        }
                    }
                    
                    Spacer()
                    Text("BigStar")
                    Spacer()
                    
                    Circle()
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                        .padding(.horizontal, 10)
                }
                .padding(.vertical)
                .padding(.top, 30)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                
                Spacer()
                
                HStack{
                    Spacer()
                    Image(systemName: "plus.circle")
                    Spacer()
                    
                    HStack{
                        Text("Message")
                            .padding(.horizontal)
                        Spacer()
                        Image(systemName: "face.smiling")
                            .padding(.horizontal)
                    }
                    .frame(width: w*0.6, height: 30)
                    .background(Color(red: 0.12, green: 0.13, blue: 0.14))
                    .cornerRadius(30)
                    
                    Spacer()
                    Image(systemName: "mic")
                    Spacer()
                }
                .padding(.vertical)
                .padding(.bottom, 30)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.17, green: 0.15, blue: 0.08), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.11, green: 0.11, blue: 0.1), location: 0.59),
                            Gradient.Stop(color: Color(red: 0.15, green: 0.13, blue: 0.12), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.7, y: 0.41),
                        endPoint: UnitPoint(x: 0.07, y: 0.41)
                    )
                )
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func loadData() -> UIImage{
        do{
            let data = try Data(contentsOf: url!)
            return UIImage(data: data)!
        }catch{
            
        }
        return UIImage(named: "")!
    }
}

#Preview {
    WallpaperTryView(bg: "")
}
