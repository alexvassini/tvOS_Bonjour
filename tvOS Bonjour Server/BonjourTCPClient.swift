//
//  BonjourTCPClient.swift
//  BonjourTCP
//
//  Created by Tibor Bodecs on 2015. 10. 15..
//  Copyright © 2015. Tibor Bodecs. All rights reserved.
//

import Foundation



class BonjourTCPClient : NSObject, NetServiceBrowserDelegate, StreamDelegate
{
	
	let kServiceType = "_myservice._tcp."
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: init
	///////////////////////////////////////////////////////////////////////////////////////////////////
	
	static let sharedInstance = BonjourTCPClient()
	
	fileprivate override init() {
		super.init()

		self.startBrowsingServices()
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: service browser
	///////////////////////////////////////////////////////////////////////////////////////////////////
	
	var serviceBrowser : NetServiceBrowser? = nil
	var services : [NetService] = []
	var servicesCallback : (([NetService]) ->())? = nil
	
	var streamsConnected = false
	var streamsConnectedCallback : ((Void) -> Void)?
	
	func startBrowsingServices() {
		self.serviceBrowser = NetServiceBrowser()
		self.serviceBrowser?.includesPeerToPeer = true
		self.serviceBrowser?.delegate = self
		self.serviceBrowser?.searchForServices(ofType: kServiceType, inDomain: "local")
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: browser delegate
	///////////////////////////////////////////////////////////////////////////////////////////////////
	
	func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {}
	func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {}
	func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {}
	func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {}
	func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {}
	
	
	func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
		NSLog("service found:" + service.name)
		self.services.append(service)
		
		if !moreComing {
			if let callback = self.servicesCallback {
				callback(self.services)
			}
		}
	}
	
	func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
		NSLog("service removed:" + service.name)
		self.services = self.services.filter() { $0 != service }
		
		if !moreComing {
			if let callback = self.servicesCallback {
				callback(self.services)
			}
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: connect to service
	///////////////////////////////////////////////////////////////////////////////////////////////////
	
	func connectTo(_ service: NetService, callback: ((Void) -> Void)?) {
		self.streamsConnectedCallback = callback

		var inputStream : InputStream? = nil
		var outputStream : OutputStream? = nil
		
		let success = service.getInputStream(&inputStream, outputStream: &outputStream)
		
		if !success {
			return NSLog("could not connect to service")
		}
		self.inputStream  = inputStream
		self.outputStream = outputStream
		
		self.openStreams()

		NSLog("connecting...")
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: streams
	///////////////////////////////////////////////////////////////////////////////////////////////////
	
	
	var inputStream : InputStream? = nil
	var outputStream : OutputStream? = nil
	var openedStreams : Int = 0
	
	
	func openStreams() {
		guard self.openedStreams == 0 else {
			return NSLog("streams already opened... \(self.openedStreams)")
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

		self.streamsConnected = false
		self.openedStreams = 0
	}
	
	


	func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		switch eventCode {
		case Stream.Event.openCompleted:
			self.openedStreams += 1
			
		break
		case Stream.Event.hasSpaceAvailable:
			if self.openedStreams == 2 && !self.streamsConnected {
				NSLog("streams connected.")
				self.streamsConnected = true
				self.streamsConnectedCallback?()
			}
			break
		default:
		break
		}
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: send message
	///////////////////////////////////////////////////////////////////////////////////////////////////
	
	func send(_ message: String) {
		guard self.openedStreams == 2 else {
			return NSLog("no open streams \(self.openedStreams)")
		}

		guard self.outputStream!.hasSpaceAvailable else {
			return NSLog("no space available")
		}
		
		let data: Data = message.data(using: String.Encoding.utf8)!
		let bytesWritten = self.outputStream!.write((data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), maxLength: data.count)
		
		guard bytesWritten == data.count else {
			self.closeStreams()
			return NSLog("something is wrong...")
		}
		NSLog("data written... \(message)")
	}
	
	
}











