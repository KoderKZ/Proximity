//
//  ClassStructs.swift
//  Proximity
//

import Foundation
import UIKit
import GooglePlaces
import FirebaseAuth
//structs for information storage
public struct Personal{
    var username:String
    var userId:String
    var friendRequests:NSMutableArray
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
    var image:String
    var profileId:String
    var timestamp:String
    var datestamp:String
    var place:AnyObject
}

//will store amt viewed for each user's chat so can they can get notifications
protocol StoreViewedDelegate{
    func changedAmt()
}

class StoreViewed{
    let amtRefs = NSMutableDictionary()
    let viewedRefs = NSMutableDictionary()
    var amtViewed = NSMutableDictionary()
    var postsAmt = NSMutableDictionary()
    var delegate:StoreViewedDelegate!
    
    class var sharedInstance:StoreViewed {
        struct Singleton {
            static let instance = StoreViewed()
        }
        
        return Singleton.instance
    }
    
    init(){}
        
    func loggedIn(){
        for var i in FirebaseHelper.personal.chats{
            let chat = i as! Chat
            addObserver(chatId: chat.id)//add observer for each chat
        }
    }
    
    func addObserver(chatId:String){
        let amtRef = FirebaseHelper.ref.child("chats").child(chatId).child("posts").observe(.value, with: { (snapshot) in
            if let dict = snapshot.value as? NSDictionary{
                self.postsAmt.removeObject(forKey: chatId)//get amt of posts
                self.postsAmt.addEntries(from: [chatId:dict.count])
                self.delegate.changedAmt()
            }
        })
        let viewedRef = FirebaseHelper.ref.child("chats").child(chatId).child("viewed").child(FirebaseHelper.personal.userId).observe(.value, with: { (snapshot) in
            if let viewed = snapshot.value as? NSDictionary{
                self.amtViewed.removeObject(forKey: chatId)//get amt viewed
                self.amtViewed.addEntries(from: [chatId:viewed[FirebaseHelper.personal.userId]])
                self.delegate.changedAmt()
            }
        })
        if !(amtRefs.allKeys as NSArray).contains(chatId){
            amtRefs.addEntries(from: [chatId:amtRef])
        }
        if !(viewedRefs.allKeys as NSArray).contains(chatId){
            viewedRefs.addEntries(from: [chatId:viewedRef])
        }
    }
    
    func removeObserver(chatId:String) {//remove observer in case of leaving chat
        let amtOb = amtRefs.object(forKey: chatId) as! UInt
        FirebaseHelper.ref.removeObserver(withHandle: amtOb)
        amtRefs.removeObject(forKey: chatId)
        
        let viewedOb = viewedRefs.object(forKey: chatId) as! UInt
        FirebaseHelper.ref.removeObserver(withHandle: viewedOb)
        viewedRefs.removeObject(forKey: chatId)
    }
    
    func addViewed(id:String){//add viewed when view messages
        if (amtViewed.allKeys as NSArray).contains(id){
            amtViewed.removeObject(forKey: id)
        }
        amtViewed.addEntries(from: [id:"\(postsAmt.object(forKey: id))"])
        FirebaseHelper.ref.child("chats").child(id).child("viewed").updateChildValues([FirebaseHelper.personal.userId:postsAmt.object(forKey: id)])
    }
    
    func getNotViewed(id:String) -> Int{//get how many not viewed for notifications
        if let firstValue = postsAmt.object(forKey: id) as? Int{
            if let secondValue = amtViewed.object(forKey: id) as? Int{
                return firstValue-secondValue
            }
        }
        return 0
    }
    
}

class StoreLogin{//store login so can stay logged in
    let defaults = UserDefaults.standard//uses defaults built in
    var username:String = ""
    var password:String = ""
    
    class var sharedInstance:StoreLogin {
        struct Singleton {
            static let instance = StoreLogin()
        }
        
        return Singleton.instance
    }
    
    init(){
        if let un = defaults.string(forKey: "username"){//gets user name and password
            username = un
        }
        if let pass = defaults.string(forKey: "password"){
            password = pass
        }
    }
    
    func setLogin(username:String, password:String) {
        defaults.set(username, forKey: "username")//sets login, will be saved even when quit app
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

//used for dating/sectioning in chat vc
public let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

//color palatte
public let darkBgColor = UIColor(displayP3Red: 0/255, green: 175/255, blue: 100/255, alpha: 1)
public let blackBgColor = UIColor(displayP3Red: 0/255, green: 100/255, blue: 25/255, alpha: 1)
public let bgColor = UIColor(displayP3Red: 72/255, green: 202/255, blue: 103/255, alpha: 1)
public let lightBgColor = UIColor(displayP3Red: 73/255, green: 194/255, blue: 202/255, alpha: 1)
public let red = UIColor(displayP3Red: 202/255, green: 82/255, blue: 73/255, alpha: 1)
public let blue = UIColor(displayP3Red: 73/255, green: 97/255, blue: 202/255, alpha: 1)
public let darkGray = UIColor(displayP3Red: 1/4, green: 1/4, blue: 1/4, alpha: 1)
public let gray = UIColor(displayP3Red: 1/2, green: 1/2, blue: 1/2, alpha: 1)
public let lightGray = UIColor(displayP3Red: 3/4, green: 3/4, blue: 3/4, alpha: 1)



extension UIView{
    //sets gradient background for uiview, is actually layer
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

//cache images so don't have to load from Firebase each time
let imageCache = NSCache<AnyObject, AnyObject>()


public func loadImageUsingUrlString(_ imageString: String, image: @escaping (UIImage) -> ()){
    //check cache for image first
    if let cachedImage = imageCache.object(forKey: imageString as AnyObject) as? UIImage {
        image(cachedImage)
    }else{
        let newImage = UIImage(data: Data(base64Encoded: imageString)!)!
        imageCache.setObject(newImage, forKey: imageString as AnyObject)
        image(newImage)
    }
    
}

import UIKit.UIGestureRecognizerSubclass//gesture recognizer, touchesbegan
class SingleTouchDownGestureRecognizer: UIGestureRecognizer{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == .possible{
            self.state = .recognized
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
}

extension UITableView {
    func reloadData(completion: @escaping ()->()) {
        UIView.animate(withDuration: 0, animations: { self.reloadData() })//completion block for reload data
        { _ in completion() }
    }
}

public func delay(_ delay:Double, closure:@escaping ()->()) {//delay block
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

extension UITextView {
    
    func centerVertically() {//sets content insets from top to center text
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        
        let topOffset = (bounds.size.height - size.height)/2
        let positiveTopOffset = max(1, topOffset)
        contentInset.top = positiveTopOffset
    }
    
    override open func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        super.setContentOffset(contentOffset, animated: false)
    }
    
}




//extra extension for keyboard dismiss
extension UIViewController:UITextFieldDelegate {
    func hideKeyboardWhenTappedAround() {//registers when tapped, will dismiss
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

let profileIcons = NSMutableDictionary()//profile icons used in chatvc, loaded in log in

func loginProcess(username:String, password:String, error: @escaping (Error) -> (), finished: @escaping (Bool) -> ()){//log in process
    Auth.auth().signIn(withEmail: username, password: password) { (user, err) in
        if err != nil{
            error(err!)//exits with error
            return
        }
        let ref = FirebaseHelper.ref.child("users").child((user?.uid)!)
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
                
        ref.observeSingleEvent(of: .value, with: { (snapshot1) in//gets all values for user, pushes to selection vc outside
            if let dictionary = snapshot1.value as? [String:AnyObject]{
                icon = dictionary["icon"] as! String
                latitude = dictionary["latitude"] as! Double
                longitude = dictionary["longitude"] as! Double
                username = dictionary["username"] as! String
                FirebaseHelper.personalRegion = CGPoint(x: -500, y: -500)
                if let latitudeReg = dictionary["latitudeRegion"] as? CGFloat{
                    if let longitudeReg = dictionary["longitudeRegion"] as? CGFloat{
                        FirebaseHelper.personalRegion = CGPoint(x: latitudeReg, y: longitudeReg)
                    }
                }

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
                                        if profileIcons.object(forKey: j as! String) == nil{
                                            requiredIconAmt += 1
                                            FirebaseHelper.ref.child("users").child(j as! String).observeSingleEvent(of:.value, with: { (snapshot) in
                                                if let profile = snapshot.value as? [String:AnyObject] {
                                                    profileIcons.addEntries(from: [(j as! String): profile["icon"]])
                                                    actualIconAmt += 1
                                                    if requiredIconAmt == actualIconAmt && finishedRequests == 1 && finishedFriendRequests{
                                                        finished(true)
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
            })
            ref.child("friends").observeSingleEvent(of: .value, with: { (snapshot4) in
                if let friendArray = snapshot4.value as? NSArray{
                    actualFriendsAmount = friendArray.count
                    for var i in friendArray{
                        FirebaseHelper.ref.child("users").child(i as! String).observeSingleEvent(of:.value, with: { (snapshot) in
                            if let dictionary = snapshot.value as? [String:AnyObject]{
                                var chats = NSMutableArray()
                                var tempFriendArray = NSMutableArray()
                                if dictionary.keys.contains("friends"){tempFriendArray = dictionary["friends"] as! NSMutableArray}
                                if dictionary.keys.contains("chats"){chats = dictionary["chats"] as! NSMutableArray}
                                let friend = Profile(username: dictionary["username"] as! String, userId: i as! String, friends: tempFriendArray, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                                profileIcons.addEntries(from: [friend.userId: friend.icon])
                                friends.add(friend)
                                finishedFriends += 1
                                if finishedFriends == friendArray.count && finishedRequests == 1 && finishedFriendRequests{
                                    FirebaseHelper.personal.friends = friends
                                    finished(true)
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
                                    let friend = Profile(username: dictionary["username"] as! String, userId: i as! String, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                                    friendRequests.add(friend)
                                }
                            })
                        }
                    }
                    finishedFriendRequests = true
                    FirebaseHelper.personal = Personal(username: username, userId: (user?.uid)!, friendRequests: friendRequests, friends: friends, icon: icon, chats: chats, latitude: latitude, longitude: longitude)
                    if actualIconAmt == requiredIconAmt{
                        finished(true)
                    }
                })
            })
        })
    }
}


