/*
 Copyright 2020 The bigstarmessenger.com Foundation C.I.C

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import UIKit

@objcMembers
public class MXKPasteboardManager: NSObject {
    
    public static let shared = MXKPasteboardManager(withPasteboard: .general)
    
    private init(withPasteboard pasteboard: UIPasteboard) {
        self.pasteboard = pasteboard
        super.init()
    }
    
    /// Pasteboard to use on copy operations. Defaults to `UIPasteboard.generalPasteboard`.
    public var pasteboard: UIPasteboard
    
}
