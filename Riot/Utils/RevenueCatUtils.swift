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

// swiftlint:disable all

import Foundation
import RevenueCat

@objc class RevenueCatUtils: NSObject {
    @objc static let publicKey = "appl_sFeRrSTtMGEEFKTRTbJzqTinbSL"
    @objc static let vipEntitlementId = "vip"
    
    @objc static var isVip: Bool = false
    private static var vipStatusObservers = [(Bool) -> Void]()

    @objc static func addObserver(_ observer: @escaping (Bool) -> Void) {
        vipStatusObservers.append(observer)
    }

    @objc static func removeObserver(_ observer: @escaping (Bool) -> Void) {
        vipStatusObservers = vipStatusObservers.filter { $0 as AnyObject !== observer as AnyObject }
    }

    @objc static func checkVipStatus(onVipStatusChecked: @escaping (Bool) -> Void) {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if let error = error {
                print("Vip error: \(error)")
                self.isVip = false
                onVipStatusChecked(self.isVip)
            } else if let customerInfo = customerInfo {
                print("Vip customerInfo: \(customerInfo)")

                let entitlements = customerInfo.entitlements
                let vipEntitlement = entitlements[self.vipEntitlementId]
                self.isVip = vipEntitlement?.isActive ?? false
                if self.isVip {
                    print("Vip User is VIP")
                } else {
                    print("Vip User is not VIP")
                }
                onVipStatusChecked(self.isVip)
            }
            
            for observer in vipStatusObservers {
                observer(self.isVip)
            }
        }
    }
}

