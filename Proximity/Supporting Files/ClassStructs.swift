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
import FirebaseAuth
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


class StoreViewed{
    let defaults = UserDefaults.standard
    let observerRefs = NSMutableDictionary()
    var amtViewed = NSMutableDictionary()
    var postsAmt = NSMutableDictionary()
    
    class var sharedInstance:StoreViewed {
        struct Singleton {
            static let instance = StoreViewed()
        }
        
        return Singleton.instance
    }
    
    init(){
        if let dict = defaults.dictionary(forKey: "viewed"){
            amtViewed = dict as! NSMutableDictionary
        }
        if let dict2 = defaults.dictionary(forKey: "amt"){
            postsAmt = dict2 as! NSMutableDictionary
        }
    }
        
    func loggedIn(){
        for var i in FirebaseHelper.personal.chats{
            let chat = i as! Chat
            addObserver(chatId: chat.id)
        }
    }
    
    func addObserver(chatId:String){
        let ref = FirebaseHelper.ref.child("chats").child(chatId).child("posts").observe(.childAdded, with: { (snapshot) in
            if let dict = snapshot.value as? NSDictionary{
                if let prevAmt = self.postsAmt.object(forKey: chatId) as? Int{
                    self.postsAmt.addEntries(from: [chatId:prevAmt+1])
                }else{
                    self.postsAmt.addEntries(from: [chatId:1])
                }
                self.defaults.set(self.postsAmt, forKey: chatId)
                self.addViewed(id: chatId)
            }
        })
        if !(observerRefs.allKeys as NSArray).contains(chatId){
            observerRefs.addEntries(from: [chatId:ref])
        }
    }
    
    func removeObserver(chatId:String) {
        let observer = observerRefs.object(forKey: chatId) as! UInt
        FirebaseHelper.ref.removeObserver(withHandle: observer)
        observerRefs.removeObject(forKey: chatId)
    }
    
    func addViewed(id:String){
        if (amtViewed.allKeys as NSArray).contains(id){
            amtViewed.removeObject(forKey: id)
        }
        if amtViewed.object(forKey: id) != nil{
            amtViewed.addEntries(from: [id:postsAmt.object(forKey: id)])
            defaults.set(amtViewed, forKey: id)
        }
    }
    
    func getNotViewed(id:String) -> Int{
        if let firstValue = postsAmt.object(forKey: id) as? Int{
            if let secondValue = amtViewed.object(forKey: id) as? Int{
                return firstValue-secondValue
            }
        }
        return 0
    }
    
}

class StoreLogin{
    let defaults = UserDefaults.standard
    var username:String = ""
    var password:String = ""
    
    class var sharedInstance:StoreLogin {
        struct Singleton {
            static let instance = StoreLogin()
        }
        
        return Singleton.instance
    }
    
    init(){
        if let un = defaults.string(forKey: "username"){
            username = un
        }
        if let pass = defaults.string(forKey: "password"){
            password = pass
        }
    }
    
    func setLogin(username:String, password:String) {
        defaults.set(username, forKey: "username")
        defaults.set(password, forKey: "password")
    }
    
    func getUsername() -> String {
        if let username = defaults.string(forKey: "username"){
            return username
        }else{
            return ""
        }
    }
    
    
    func getPassword() -> String {
        if let password = defaults.string(forKey: "password"){
            return password
        }else{
            return ""
        }
    }
}


public let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

public let darkBgColor = UIColor(displayP3Red: 0/255, green: 175/255, blue: 100/255, alpha: 1)
public let blackBgColor = UIColor(displayP3Red: 0/255, green: 100/255, blue: 25/255, alpha: 1)
public let bgColor = UIColor(displayP3Red: 0/255, green: 214/255, blue: 129/255, alpha: 1)
public let lightBgColor = UIColor(displayP3Red: 200/255, green: 255/255, blue: 225/255, alpha: 1)
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

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(_ urlString: String) {

        loadImageUsingUrlString(urlString) { success in
            self.image = success
        }
    }
    
}

public func loadImageUsingUrlString(_ urlString: String, image: @escaping (UIImage) -> ()){
    
    
    //check cache for image first
    if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
        image(cachedImage)
    }else{
        FirebaseHelper.storageRef.child("images/\(urlString).jpeg").getData(maxSize: 50*(1024*1024), completion: { (data, err) in
            if let error = err{
                print("couldn't download image")
                return
            }
            if let downloadedImage = UIImage(data: data!) {
                imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
            }
        })
    }
    
}

extension UITableView {
    func reloadData(completion: @escaping ()->()) {
        UIView.animate(withDuration: 0, animations: { self.reloadData() })
        { _ in completion() }
    }
}

public func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

extension UITextView {
    
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale)
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = positiveTopOffset
    }
    
    override open func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        super.setContentOffset(contentOffset, animated: false)
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

func loginProcess(username:String, password:String, vc: ChatViewController, error: @escaping (Error) -> (), finished: @escaping (ChatViewController) -> ()){
    Auth.auth().signIn(withEmail: username, password: password) { (user, err) in
        if err != nil{
            error(err!)
        }
        let ref = FirebaseHelper.ref.child("users").child((user?.uid)!)
        //            let chats = ref.child("chats").
//        let navigationController = AppDelegate.navi
        var icon = ""
        var username = ""
        var latitude:Double = 0
        var longitude:Double = 0
        let chats = NSMutableArray()
        let friends = NSMutableArray()
        let friendRequests = NSMutableArray()
        
        var requiredIconAmt = 0
        var actualIconAmt = 0
        var finishedFriends = 0
        var finishedRequests = 0
        var actualFriendsAmount = 0
        var finishedFriendRequests = false
                
        ref.observeSingleEvent(of: .value, with: { (snapshot1) in
            if let dictionary = snapshot1.value as? [String:AnyObject]{
                icon = dictionary["icon"] as! String
                latitude = dictionary["latitude"] as! Double
                longitude = dictionary["longitude"] as! Double
                username = dictionary["username"] as! String
            }
            ref.child("chats").observeSingleEvent(of: .value, with: { (snapshot2) in
                if let array = snapshot2.value as? NSArray{
                    for var i in array{
                        FirebaseHelper.ref.child("chats").child(i as! String).observeSingleEvent(of: .value, with: { (chatSnapshot) in
                            if let dictionary = chatSnapshot.value as? [String:AnyObject]{
                                
                                var chat = Chat(id: i as! String, chatName: dictionary["chatName"] as! String, joinType: dictionary["joinType"] as! Int, members: NSMutableArray(), posts: NSMutableArray())
                                if let images = dictionary["images"] as? NSMutableArray{
                                    for var i in images{
                                        loadImageUsingUrlString(i as! String, image: { (image) in})
                                    }
                                }
                                if let members = dictionary["members"]{
                                    chat.members = members as! NSMutableArray
                                    for var j in chat.members{
                                        if vc.profileIcons.object(forKey: j as! String) == nil{
                                            requiredIconAmt += 1
                                            FirebaseHelper.ref.child("users").child(j as! String).observeSingleEvent(of:.value, with: { (snapshot) in
                                                if let profile = snapshot.value as? [String:AnyObject] {
                                                    vc.profileIcons.addEntries(from: [(j as! String): profile["icon"]])
                                                    actualIconAmt += 1
                                                    if requiredIconAmt == actualIconAmt && finishedRequests == 1 && finishedFriendRequests{
                                                        finished(vc)
                                                    }else if requiredIconAmt == actualIconAmt && finishedRequests == 0{
                                                        finishedRequests += 1
                                                    }
                                                }
                                            })
                                        }
                                    }
                                }
                                chats.add(chat)
                            }
                        })
                    }
                }else{
                    finishedRequests += 1
                }
                ref.child("friends").observeSingleEvent(of: .value, with: { (snapshot4) in
                    if let friendArray = snapshot4.value as? NSArray{
                        actualFriendsAmount = friendArray.count
                        for var i in friendArray{
                            FirebaseHelper.ref.child("users").child(i as! String).observeSingleEvent(of:.value, with: { (snapshot) in
                                if let dictionary = snapshot.value as? [String:AnyObject]{
                                    var friends = NSMutableArray()
                                    var chats = NSMutableArray()
                                    if dictionary.keys.contains("chats"){chats = dictionary["chats"] as! NSMutableArray}
                                    var friend = Profile(username: dictionary["username"] as! String, userId: i as! String, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                                    friends.add(friend)
                                    finishedFriends += 1
                                    if finishedFriends == friendArray.count && finishedRequests == 1 && finishedFriendRequests{
                                        FirebaseHelper.personal.friends = friends
                                        finished(vc)
                                    }else if finishedFriends == friendArray.count && finishedRequests == 0{
                                        finishedRequests += 1
                                    }
                                }
                            })
                        }
                    }else{
                        finishedRequests += 1
                    }
                    
                    ref.child("friendRequests").observeSingleEvent(of: .value, with: { (snapshot5) in
                        if let array = snapshot5.value as? NSArray{
                            for var i in array{
                                FirebaseHelper.ref.child("users").child(i as! String).observeSingleEvent(of:.value, with: { (snapshot) in
                                    if let dictionary = snapshot.value as? [String:AnyObject]{
                                        var friends = NSMutableArray()
                                        var chats = NSMutableArray()
                                        if dictionary.keys.contains("friends"){friends = dictionary["friends"] as! NSMutableArray}
                                        if dictionary.keys.contains("chats"){chats = dictionary["chats"] as! NSMutableArray}
                                        var friend = Profile(username: dictionary["username"] as! String, userId: i as! String, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                                        friendRequests.add(friend)
                                    }
                                })
                            }
                        }
                        finishedFriendRequests = true
                        FirebaseHelper.personal = Personal(username: username, userId: (user?.uid)!, friendRequests: friendRequests, email: username, friends: friends, icon: icon, chats: chats, latitude: latitude, longitude: longitude)
                        if actualIconAmt == requiredIconAmt{
                            finished(vc)
                        }
                    })
                })
                
            })
        })
    }
}


