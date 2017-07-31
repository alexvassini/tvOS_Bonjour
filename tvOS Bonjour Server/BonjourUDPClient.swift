//
//  Client.swift
//  Impixable
//
//  Created by Tibor Bodecs on 2015. 09. 29..
//  Copyright © 2015. Tibor Bodecs. All rights reserved.
//
import Foundation
import CocoaAsyncSocket


#if os(OSX)
    private let deviceName = NSHost.currentHost().localizedName!
#else
    import UIKit
    private let deviceName = UIDevice.current.name
#endif


class BonjourUDPClient : NSObject, NetServiceBrowserDelegate, NetServiceDelegate, GCDAsyncUdpSocketDelegate
{
    
    let socket = GCDAsyncUdpSocket()
    let socketPort: UInt16 = 5566
    
    var hostName : String?
    
    let serviceDomain = "local"
    let serviceType = "_udp_discovery._udp."
    var serviceBrowser : NetServiceBrowser? = nil
    var services : [NetService] = []
    var servicesCallback : (([NetService]) ->())? = nil
    
    var resolved = false
    var resolvedCallback: ((Void) -> Void)? = nil
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    //  MARK: init
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    static let sharedInstance = BonjourUDPClient()
    
    fileprivate override init() {
        super.init()
        
        self.serviceBrowser = NetServiceBrowser()
        self.serviceBrowser?.delegate = self
        self.serviceBrowser?.searchForServices(ofType: serviceType, inDomain: self.serviceDomain)
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    //  MARK: NSNetServiceDelegate
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let host = sender.hostName else {
            return NSLog("could not resolve host")
        }
        self.hostName = host
        
        NSLog("resolved host: \(self.hostName!)")
        
        if !self.resolved {
            self.resolved = true
            self.resolvedCallback?()
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    //  MARK: message sending API
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    func send(_ message: String) {
        if let host = self.hostName {
            let data = message.data(using: String.Encoding.utf8)
            self.socket.send(data!, toHost: host, port: self.socketPort, withTimeout: -1, tag: 0)
        }
        else {
            NSLog("no hosts resolved!")
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    //  MARK: NSNetServiceBrowserDelegate
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {}
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {}
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {}
    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {}
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {}
    
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        NSLog("found:" + service.name)
        
        self.services.append(service)
        
        if !moreComing {
            if let callback = self.servicesCallback {
                callback(self.services)
            }
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        NSLog("removed:" + service.name)
        
        self.services = self.services.filter() { $0 != service }
        
        if !moreComing {
            if let callback = self.servicesCallback {
                callback(self.services)
            }
        }
    }
    
    
}
