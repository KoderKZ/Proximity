//
//  ClassStructs.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/5/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
import GooglePlaces
//Classes to cast to when pulling out from JSON from backend
public struct Personal{
    var username:String
    var userId:String
    var friendRequests:NSMutableArray
    var email:String
    var friends:NSMutableArray
    var icon:String
    var chats:NSMutableArray
    var latitude:Double
    var longitude:Double
}

public struct Profile{
    var username:String
    var userId:String
    var friends:NSArray
    var icon:String
    var chats:NSArray
    var latitude:Double
    var longitude:Double
}

public struct Chat{
    var id:String
    var chatName:String
    var joinType:Int
    var members:NSMutableArray
    var posts:NSMutableArray
}

public struct Post{
    var chatId:String
    var text:String
//    var poll:Poll
    var image:String
    var profileId:String
    var timestamp:String
    var datestamp:String
    var place:AnyObject
}

public struct Poll{
    var question:String
    var answer1:String
    var amount1:Int
    var answer2:String
    var amount2:Int
    var answer3:String
    var amount3:Int
    var answer4:String
    var amount4:Int
}

public let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

public let darkBgColor = UIColor(displayP3Red: 0, green: 25/255, blue: 40/255, alpha: 1)
public let bgColor = UIColor(displayP3Red: 0, green: 29/255, blue: 50/255, alpha: 1)
public let darkGray = UIColor(displayP3Red: 1/4, green: 1/4, blue: 1/4, alpha: 1)
public let gray = UIColor(displayP3Red: 1/2, green: 1/2, blue: 1/2, alpha: 1)
public let lightGray = UIColor(displayP3Red: 3/4, green: 3/4, blue: 3/4, alpha: 1)



extension UIView{
    func setGradientBackground(colorOne:UIColor, colorTwo:UIColor){
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame.size = CGSize(width: bounds.size.width+bounds.size.height, height: bounds.size.height)
        gradientLayer.frame.origin = CGPoint(x: 0, y: 0)
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

//extra extension for keyboard dismiss
extension UIViewController:UITextFieldDelegate {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        textField.resignFirstResponder()
        return false
    }
}


