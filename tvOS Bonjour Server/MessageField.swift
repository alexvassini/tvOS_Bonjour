//
//  MessageField.swift
//  tvOS Bonjour Server
//
//  Created by BEPID on 31/07/17.
//  Copyright © 2017 Alexandre  Vassinievski. All rights reserved.
//

import UIKit

@IBDesignable class MessageField: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    func setup() {
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
    }
}
