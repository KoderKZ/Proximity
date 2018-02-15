//
//  SelectionView.swift
//  Proximity
//

import Foundation
import UIKit
class SelectionView:UIView{
    var chatsButton:UIButton!
    var friendsButton:UIButton!
    var searchButton:UIButton!
    var createButton:UIButton!
    var profileButton:UIButton!
    let margin:CGFloat = 15
    var tab = 0
    var width:CGFloat!
    var indicator:UIView!
    var delegate:SelectionViewDelegate!
    required override init(frame:CGRect) {
        //sets up tabs to click on
        super.init(frame: frame)
        self.backgroundColor = darkBgColor
        self.layer.cornerRadius = self.frame.size.height/2
        width = (self.frame.size.width-(margin*6))/5
        let yCoord = self.frame.size.height/2-width/2
        chatsButton = UIButton(frame: CGRect(x: margin, y: yCoord, width: width, height: width))
        chatsButton.tag = 0
        chatsButton.setImage(UIImage(named:"chats"), for: .normal)
        
        friendsButton = UIButton(frame: CGRect(x: (margin*2)+width, y: yCoord, width: width, height: width))
        friendsButton.tag = 1
        friendsButton.setImage(UIImage(named:"friends"), for: .normal)
        
        searchButton = UIButton(frame: CGRect(x: (margin*3)+width*2, y: yCoord, width: width, height: width))
        searchButton.tag = 2
        searchButton.setImage(UIImage(named:"search"), for: .normal)
        
        createButton = UIButton(frame: CGRect(x: (margin*4)+width*3, y: yCoord, width: width, height: width))
        createButton.tag = 3
        createButton.setImage(UIImage(named:"create"), for: .normal)
        
        profileButton = UIButton(frame: CGRect(x: (margin*5)+width*4, y: yCoord, width: width, height: width))
        profileButton.tag = 4
        profileButton.setImage(UIImage(named:"profile"), for: .normal)
        
        chatsButton.showsTouchWhenHighlighted = false
        friendsButton.showsTouchWhenHighlighted = false
        searchButton.showsTouchWhenHighlighted = false
        createButton.showsTouchWhenHighlighted = false
        profileButton.showsTouchWhenHighlighted = false
        
        chatsButton.adjustsImageWhenHighlighted = false
        friendsButton.adjustsImageWhenHighlighted = false
        searchButton.adjustsImageWhenHighlighted = false
        createButton.adjustsImageWhenHighlighted = false
        profileButton.adjustsImageWhenHighlighted = false
        
        chatsButton.addTarget(self, action: #selector(tappedSelectionButton(sender:)), for: .touchUpInside)
        friendsButton.addTarget(self, action: #selector(tappedSelectionButton(sender:)), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(tappedSelectionButton(sender:)), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(tappedSelectionButton(sender:)), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(tappedSelectionButton(sender:)), for: .touchUpInside)
        
        addSubview(chatsButton)
        addSubview(friendsButton)
        addSubview(searchButton)
        addSubview(createButton)
        addSubview(profileButton)
        
        let x = (margin*CGFloat(tab+1))+(width*CGFloat(Double(tab)+0.5))
        indicator = UIView(frame: CGRect(x: x-(width/8*3), y: self.frame.size.height-10, width: width/4*3, height: 3))
        indicator.backgroundColor = .white
        indicator.layer.cornerRadius = 1.5
        addSubview(indicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTab(tab:Int) {
        //move indicator to selected tab
        self.tab = tab
        let x = (margin*CGFloat(tab+1))+(width*CGFloat(Double(tab)+0.5))
        indicator.frame.origin.x = x-(width/8*3)
    }
    
    @objc func tappedSelectionButton(sender:UIButton){
        delegate.selectionTapped(tag: sender.tag)//delegates function to other vc
    }
    
    
}

protocol SelectionViewDelegate {
    func selectionTapped(tag:Int)
}
