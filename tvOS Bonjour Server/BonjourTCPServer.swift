//
//  BonjourTCP.swift
//  BonjourTCP
//
//  Created by Tibor Bodecs on 2015. 10. 15..
//  Copyright © 2015. Tibor Bodecs. All rights reserved.
//


import Foundation


#if os(OSX)
	private let deviceName = NSHost.currentHost().localizedName!
#else
	import UIKit
	private let deviceName = UIDevice.current.name
#endif


class BonjourTCPServer : NSObject, NetServiceDelegate, StreamDelegate
{

	let kWiTapBonjourType = "_myservice._tcp."

	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: init
	///////////////////////////////////////////////////////////////////////////////////////////////////

	static let sharedInstance = BonjourTCPServer()
	
	fileprivate override init() {
		super.init()
		
		self.service = NetService(domain: "local.", type: kWiTapBonjourType, name: deviceName, port: 0)
		self.service?.includesPeerToPeer = true
		self.service?.delegate = self
		self.service?.publish(options: .listenForConnections)
		
		self.serviceRunning = true
		
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: service
	///////////////////////////////////////////////////////////////////////////////////////////////////
	
	var service : NetService? = nil
	var serviceRunning = false
	var registeredName : String? = nil

	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: NSNetServiceDelegate
	///////////////////////////////////////////////////////////////////////////////////////////////////

	
	func netServiceWillPublish(_ sender: NetService) {}
	func netServiceDidPublish(_ sender: NetService) {
		self.registeredName = sender.name
	}
	
	func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {}
	func netServiceWillResolve(_ sender: NetService) {}
	func netServiceDidResolveAddress(_ sender: NetService) {}
	func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {}
	func netServiceDidStop(_ sender: NetService) {}
	func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {}
	

	func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
		OperationQueue.main.addOperation { [weak self] in
			if self?.inputStream != nil {
				inputStream.open()
				inputStream.close()
				outputStream.open()
				outputStream.close()
				return NSLog("connection already open.")
			}
			self?.service?.stop()
			self?.serviceRunning = false
			self?.registeredName = nil
			
			self?.inputStream = inputStream
			self?.outputStream = outputStream
			
			self?.openStreams()
			
			NSLog("connection accepted: streams opened.")
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: streams
	///////////////////////////////////////////////////////////////////////////////////////////////////

	
	var inputStream : InputStream? = nil
	var outputStream : OutputStream? = nil
	var openedStreams : Int = 0


	func openStreams() {
		guard self.openedStreams == 0 else {
			return
		}

		self.inputStream?.delegate = self
		self.inputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		self.inputStream?.open()
		
		self.outputStream?.delegate = self
		self.outputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		self.outputStream?.open()
	}


	func closeStreams() {
		self.inputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		self.inputStream?.close()
		self.inputStream = nil
		
		self.outputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		self.outputStream?.close()
		self.outputStream = nil
		
		self.openedStreams = 0
	}
	
	

	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: nsstream delegate
	///////////////////////////////////////////////////////////////////////////////////////////////////

	var dataReceivedCallback : ((String) -> ())? = nil
	func stream(_ aStream: Stream, handle eventCode: Stream.Event) {

		switch eventCode {
		case Stream.Event():

		break
		case Stream.Event.openCompleted:
			self.openedStreams += 1
			
			if self.openedStreams == 2 {
				self.service?.stop()
				self.serviceRunning = false
				self.registeredName = nil
			}
		break
		case Stream.Event.hasBytesAvailable:
			guard let inputStream = self.inputStream else {
				return NSLog("no input stream")
			}
			
			let bufferSize     = 4096
			var buffer         = Array<UInt8>(repeating: 0, count: bufferSize)
			var message        = ""

			while inputStream.hasBytesAvailable {
				let len = inputStream.read(&buffer, maxLength: bufferSize)
				if len < 0 {
					NSLog("error reading stream...")
					return self.closeStreams()
				}
				if len > 0 {
					message += NSString(bytes: &buffer, length: len, encoding: String.Encoding.utf8.rawValue)! as String
				}
				if len == 0 {
					NSLog("no more bytes available...")
					break
				}
			}
			self.dataReceivedCallback?(message)
		break

		default:
		break
		}
	}

}










