//
//  CardCollectionViewCell.swift
//  tvOS Bonjour Server
//
//  Created by BEPID on 31/07/17.
//  Copyright © 2017 Alexandre  Vassinievski. All rights reserved.
//

import UIKit

class CardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var shadowView: UIView!
    
    @IBOutlet weak var cardView: UIView!
    
    
    
    override func awakeFromNib() {
        
        shadowView.layer.shadowColor = UIColor.gray.cgColor
        shadowView.layer.shadowOpacity = 0.3
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowView.layer.shadowRadius = 2
        shadowView.layer.shouldRasterize = false
        shadowView.layer.cornerRadius = 4
        
        cardView.layer.cornerRadius = 4
        cardView.clipsToBounds = true
    }
    
    }
