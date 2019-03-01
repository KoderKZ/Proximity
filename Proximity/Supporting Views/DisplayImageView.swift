//
//  DisplayImageView.swift
//  Proximity
//
//  Created by Kevin Zhou on 1/4/18.
//  Copyright © 2018 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
class DisplayImageView:UIView{//displays image in chat vc
    var imageView:UIImageView!
    override init(frame:CGRect) {
        super.init(frame: frame)
        self.alpha = 0
        setUpViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setImage(image:UIImage) {//sets image to display, sets position
        imageView.frame.size = sizeForImage(image: image)
        imageView.frame.origin = CGPoint(x: self.frame.size.width/2-imageView.frame.size.width/2, y: self.frame.size.height/2-imageView.frame.size.height/2)
        imageView.layer.masksToBounds = true
    }
    
    func setUpViews() {//sets up basic views
        let background = UIView(frame:self.frame)
        background.backgroundColor = .black
        background.alpha = 0.7
        addSubview(background)
        
        imageView = UIImageView()
        addSubview(imageView)
    }
    
    func appear() {//fades in
        UIView.animate(withDuration: 0.5) {
            self.alpha = 1
        }
    }
    
    func disappear() {//fades out
        UIView.animate(withDuration: 0.5) {
            self.alpha = 0
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        disappear()//if touched, will fade out
    }
    
    fileprivate func sizeForImage(image:UIImage) -> CGSize{//scales image to same size every time
        let scale = self.frame.size.width/4*3/image.size.width
        return CGSize(width: image.size.width*scale, height: image.size.height*scale)
    }
    
}
