//
//  Bluetooth.swift
//  CoreBluetooth
//
//  Created by Tibor Bodecs on 2015. 10. 15..
//  Copyright © 2015. Tibor Bodecs. All rights reserved.
//

import Foundation
import CoreBluetooth


class Bluetooth
{
	fileprivate static let serviceUUID         = "A20A39F4-73F5-4BC4-A12F-17D1AD07A961"
	fileprivate static let characteristicsUUID = "18590F7E-DB05-467E-8757-72F6FAEB13D4"

	static let Service				       = CBUUID(string: Bluetooth.serviceUUID)
	static let Characteristics             = CBUUID(string: Bluetooth.characteristicsUUID)
	
	static let EOM                         = "EOM"
	static let EOMData                     = Bluetooth.EOM.data(using: String.Encoding.utf8)!
}
