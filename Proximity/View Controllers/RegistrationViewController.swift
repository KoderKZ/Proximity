//
//  RegistrationViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/26/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
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
    
    @IBOutlet weak var errorLabel: UILabel!
    var image:UIImage!
    override func viewDidLoad() {
        self.hideKeyboardWhenTappedAround()
        self.view.setGradientBackground(colorOne: bgColor, colorTwo: darkGray)
        usernameTextField.returnKeyType = .done
        usernameTextField.delegate = self
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: usernameTextField.frame.size.height, width: self.view.frame.size.width-(usernameTextField.frame.origin.x*2), height: 1)
        border1.backgroundColor = UIColor.white.cgColor
        usernameTextField.layer.addSublayer(border1)
        
        let border2 = CALayer()
        border2.frame = CGRect(x: 0, y: emailTextField.frame.size.height, width: self.view.frame.size.width-(emailTextField.frame.origin.x*2), height: 1)
        border2.backgroundColor = UIColor.white.cgColor
        emailTextField.layer.addSublayer(border2)
        
        let border3 = CALayer()
        border3.frame = CGRect(x: 0, y: passwordTextField.frame.size.height, width: self.view.frame.size.width-(passwordTextField.frame.origin.x*2), height: 1)
        border3.backgroundColor = UIColor.white.cgColor
        passwordTextField.layer.addSublayer(border3)
        
        let border4 = CALayer()
        border4.frame = CGRect(x: 0, y: confirmPasswordTextField.frame.size.height, width: self.view.frame.size.width-(confirmPasswordTextField.frame.origin.x*2), height: 1)
        border4.backgroundColor = UIColor.white.cgColor
        confirmPasswordTextField.layer.addSublayer(border4)
        
        chooseImageButton.backgroundColor = .clear
        chooseImageButton.layer.cornerRadius = chooseImageButton.frame.size.width/2
        chooseImageButton.layer.borderWidth = 3
        chooseImageButton.layer.borderColor = UIColor.black.cgColor
        
        chooseImageButton.setTitleColor(.white, for: .normal)
        chooseImageButton.layer.masksToBounds = true
        
        finishButton.backgroundColor = .clear
        finishButton.setGradientBackground(colorOne: darkGray, colorTwo: gray)
        
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.layer.masksToBounds = true


        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        chooseImageButton.frame.size.height = chooseImageButton.frame.size.width
        if image != nil{
            chooseImageButton.setBackgroundImage(image!, for: .normal)
            chooseImageButton.setTitle("", for: .normal)
        }
    }
    
    @IBAction func chooseImageTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated:true, completion: nil)
        
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        print(image.size)
        self.image = image
    }
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func finishButtonTapped(_ sender: Any) {
        errorLabel.alpha = 0
        
        if passwordTextField.text! == confirmPasswordTextField.text!{
            if chooseImageButton.backgroundImage(for: .normal) != nil && usernameTextField.text != nil && emailTextField.text != nil && passwordTextField.text != nil{
                Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                    if error != nil{
                        self.errorLabel.text = error?.localizedDescription
                        self.errorLabel.alpha = 1
                        return
                    }
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController")
                    FirebaseHelper.personal = Personal(username: self.usernameTextField.text!, userId: FirebaseHelper.personal.userId, friendRequests: NSMutableArray(), email: self.emailTextField.text!, friends: NSMutableArray(), icon: (UIImageJPEGRepresentation(self.chooseImageButton.backgroundImage(for: .normal)!, 1.0)?.base64EncodedString())!, chats: NSMutableArray(), latitude: 0, longitude: 0)
                    self.navigationController?.pushViewController(vc!, animated: true)
                    FirebaseHelper.updatePersonal()
                }

                FirebaseHelper.ref.child("names").updateChildValues([FirebaseHelper.personal.username:FirebaseHelper.personal.userId])
            }else{
                errorLabel.alpha = 1
                errorLabel.text = "Please fill in everything"
            }
        }else{
            errorLabel.alpha = 1
            errorLabel.text = "Passwords do not match"
        }
    }
}
