//
//  RegistrationViewController.swift
//  Proximity
//

import Foundation
import UIKit
import FirebaseAuth
class RegistrationViewController:UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    var moveView:Bool = false
    
    @IBOutlet weak var errorLabel: UILabel!
    var image:UIImage!
    override func viewDidLoad() {
        //set up ui/default values
        self.hideKeyboardWhenTappedAround()
        self.view.backgroundColor = .clear
        self.view.setGradientBackground(colorOne: lightGray, colorTwo: bgColor)
        usernameTextField.returnKeyType = .done
        usernameTextField.delegate = self
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: usernameTextField.frame.size.height, width: self.view.frame.size.width-(usernameTextField.frame.origin.x*2), height: 1)
        border1.backgroundColor = UIColor.black.cgColor
        usernameTextField.layer.addSublayer(border1)
        
        let border2 = CALayer()
        border2.frame = CGRect(x: 0, y: emailTextField.frame.size.height, width: self.view.frame.size.width-(emailTextField.frame.origin.x*2), height: 1)
        border2.backgroundColor = UIColor.black.cgColor
        emailTextField.layer.addSublayer(border2)
        
        let border3 = CALayer()
        border3.frame = CGRect(x: 0, y: passwordTextField.frame.size.height, width: self.view.frame.size.width-(passwordTextField.frame.origin.x*2), height: 1)
        border3.backgroundColor = UIColor.black.cgColor
        passwordTextField.layer.addSublayer(border3)
        passwordTextField.delegate = self
        
        let border4 = CALayer()
        border4.frame = CGRect(x: 0, y: confirmPasswordTextField.frame.size.height, width: self.view.frame.size.width-(confirmPasswordTextField.frame.origin.x*2), height: 1)
        border4.backgroundColor = UIColor.black.cgColor
        confirmPasswordTextField.layer.addSublayer(border4)
        confirmPasswordTextField.delegate = self
        
        chooseImageButton.backgroundColor = .clear

        chooseImageButton.layer.borderWidth = 3
        chooseImageButton.layer.borderColor = UIColor.black.cgColor
        
        chooseImageButton.setTitleColor(.black, for: .normal)
        chooseImageButton.layer.masksToBounds = true
        
        finishButton.backgroundColor = .clear
        finishButton.setGradientBackground(colorOne: darkGray.withAlphaComponent(0.05), colorTwo: gray.withAlphaComponent(0.05))

        finishButton.setTitleColor(.black, for: .normal)
        finishButton.layer.masksToBounds = true

        
        usernameTextField.attributedPlaceholder = NSAttributedString(string: "Username",
                                                               attributes: [NSAttributedStringKey.foregroundColor: UIColor.black])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                     attributes: [NSAttributedStringKey.foregroundColor: UIColor.black])
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email",
                                                                     attributes: [NSAttributedStringKey.foregroundColor: UIColor.black])
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: "Confirm Password",
                                                                     attributes: [NSAttributedStringKey.foregroundColor: UIColor.black])

        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    
    //keyboard updaters
    @objc func keyboardWillShow(notification:NSNotification){
        if moveView{
            let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
            let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double

            UIView.animate(withDuration: keyboardDuration) {
                self.view.frame.origin.y -= keyboardFrame.size.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        if moveView{
            let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
            let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect

            UIView.animate(withDuration: keyboardDuration) {
                self.view.frame.origin.y += keyboardFrame.size.height
            }
        }
        moveView = false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        moveView = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //set up ui
        chooseImageButton.layer.cornerRadius = (self.view.frame.size.width-chooseImageButton.frame.origin.x*2)/2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if image != nil{
            chooseImageButton.setBackgroundImage(image!, for: .normal)
            chooseImageButton.setTitle("", for: .normal)
        }
    }
    
    @IBAction func chooseImageTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            //push to image picker
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    //image picker delegate functions
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated:true, completion: nil)
        
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        self.image = image
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {//only allow alphabet
        let characterSet = CharacterSet.letters
        
        if string.rangeOfCharacter(from: characterSet.inverted) != nil {
            return false
        }
        return true
    }
    
    @IBAction func backTapped(_ sender: Any) {//pops current vc
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func finishButtonTapped(_ sender: Any) {
        errorLabel.alpha = 0
        
        if passwordTextField.text! == confirmPasswordTextField.text!{
            //checks if passwords match
            if chooseImageButton.backgroundImage(for: .normal) != nil && usernameTextField.text != nil && emailTextField.text != nil && passwordTextField.text != nil{
                //checks if everything is filled in
                Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                    //Firebase helps create user, now push to selectionVc
                    if error != nil{
                        self.errorLabel.text = error?.localizedDescription
                        self.errorLabel.alpha = 1
                        self.errorLabel.baselineAdjustment = .alignCenters
                        
                        return
                    }
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "SelectionViewController")
                    //set own user
                    FirebaseHelper.personal = Personal(username: self.usernameTextField.text!, userId: (user?.uid)!, friendRequests: NSMutableArray(), friends: NSMutableArray(), icon: (UIImageJPEGRepresentation(self.chooseImageButton.backgroundImage(for: .normal)!, 1.0)?.base64EncodedString())!, chats: NSMutableArray(), latitude: 0, longitude: 0)
                    FirebaseHelper.updatePersonal()
                    FirebaseHelper.ref.child("users").child((user?.uid)!).updateChildValues(["latitudeRegion":"-500","longitudeRegion":"-500"])
                    FirebaseHelper.ref.child("names").updateChildValues([FirebaseHelper.personal.username:FirebaseHelper.personal.userId])
                    self.navigationController?.pushViewController(vc!, animated: true)//push to next vc
                }
            }else{
                //print error message
                errorLabel.alpha = 1
                errorLabel.text = "Please fill in everything"
                errorLabel.baselineAdjustment = .alignCenters
            }
        }else{
            //print error message
            errorLabel.alpha = 1
            errorLabel.text = "Passwords do not match"
            errorLabel.baselineAdjustment = .alignCenters
        }
    }
}
