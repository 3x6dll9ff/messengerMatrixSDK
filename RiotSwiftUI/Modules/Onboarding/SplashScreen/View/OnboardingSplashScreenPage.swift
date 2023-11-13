//
// Copyright 2021 New Vector Ltd
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

struct OnboardingSplashScreenPage: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    /// The content that this page should display.
    @ObservedObject var viewModel: OnboardingSplashScreenViewModel.Context
    @State private var showButtons: Bool = false
    @State private var currentPage = 0
    let tabTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    // MARK: - Views
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(viewModel.viewState.content.indices, id: \.self){index in
                VStack {
                    Text(viewModel.viewState.content[index].title)
                        .font(theme.fonts.title1B)
                        .foregroundColor(theme.colors.primaryContent)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 15)
                        .padding(.horizontal, 25)
                        .onAppear{
                            if index == viewModel.viewState.content.count-1{
                                showButtons = true
                            }else{
                                showButtons = false
                            }
                        }
                    
                    Text(viewModel.viewState.content[index].message)
                        .font(theme.fonts.title3SB)
                        .foregroundColor(theme.colors.primaryContent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 25)
                        .padding(.bottom, showButtons ? 20 : 200)
                    
                    if showButtons{
                        buttons
                    }
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/2-50)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .onReceive(tabTimer) { _ in
            withAnimation{
                currentPage += 1
                if currentPage == viewModel.viewState.content.count{
                    currentPage = 0
                }
                if currentPage == viewModel.viewState.content.count-1{
                    showButtons = true
                }else{
                    showButtons = false
                }
            }
        }
    }
    
    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 1) {
            Button {
                viewModel.send(viewAction: .register)
                print("TAP: REGISTER")
            } label: {
                Text(VectorL10n.onboardingSplashRegisterButtonTitle)
                    .foregroundColor(.white)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 90)
                    .background(theme.isDark ? Color(red: 0.14, green: 0.15, blue: 0.2) : Color(red: 0.43, green: 0.45, blue: 0.6)
                    )
                    .cornerRadius(30)
            }
            
            Spacer().frame(height: 5)
            
            Button {
                viewModel.send(viewAction: .login)
                print("TAP: LOGIN")
            } label: {
                Text(VectorL10n.onboardingSplashLoginButtonTitle)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryContent)
                    .padding(10)
            }
        }
        .padding(.horizontal, 16)
        .readableFrame()
    }
}
