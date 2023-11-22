//
//  SUIProfilePictureViewInterface.swift
//
import Foundation
import SwiftUI

@objc
class SUIProfilePictureViewInterface: NSObject {
 
    @available(iOS 15.0, *)
    @objc func makeShipDetailsUI(_ name: String) -> UIViewController{
        var details = SUIProfilePictureView()
        details.shipName = name
        return UIHostingController(rootView: details)
    }
}
