//
//  HostManager.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/2/16.
//  Copyright © 2016 delong. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class HostManager: NSObject, GCDAsyncSocketDelegate {

    static let sharedInstance = HostManager()

    // Make public??
    static let DataReceivedNotification = "DataReceivedNotification"
    static let ConnectionEstablishedNotification = "ConnectionEstablishedNotification"
    static let ConnectionLostNotification = "ConnectionLostNotification"
    static let Port:UInt16 = 1234



    let WELCOME_MSG = 0
    let ECHO_MSG    = 1
    let WARNING_MSG = 2

    let READ_TIMEOUT = 15.0
    let READ_TIMEOUT_EXTENSION = 10.0

    var connectedSockets: NSMutableArray = NSMutableArray(capacity: 1)
    var socketQueue: dispatch_queue_t = dispatch_queue_create("hostSocketQueue", nil)
    var listenSocket: GCDAsyncSocket = GCDAsyncSocket()
    var isRunning: Bool = false

    override init() {
        super.init()
        self.listenSocket.delegate = self
        self.listenSocket.delegateQueue = socketQueue
    }

    func start() -> Bool {
        if self.isRunning {
            print("Server already started")
            return true
        }

        do {
            try self.listenSocket.acceptOnPort(HostManager.Port)
        } catch {
            print("Error starting server")
            return false
        }

        print("Echo server started on port \(self.listenSocket.localHost) : \(self.listenSocket.localPort)")

        //TODO: Get actual ip address
        //http://stackoverflow.com/questions/14037129/null-result-on-converting-nsdata-to-nsstring
        //self.listenSocket.localAddress

        self.isRunning = true
        return true
    }

    func stop() {
        if isRunning {
            // Stop accepting connections
            self.listenSocket.disconnect()

            // Stop any client connections
            synchronize(connectedSockets) {
                for connection in self.connectedSockets {
                    // Call disconnect on the socket,
                    // which will invoke the socketDidDisconnect: method,
                    // which will remove the socket from the list.
                    connection.disconnect()
                }
            }

            print("Stopped Echo server")
            self.isRunning = false;
        } else {
            print("Server already stopped")
        }
    }

    func writeData(data: String) {
        let tempData = data + "\r\n"
        let msgData = tempData.dataUsingEncoding(NSUTF8StringEncoding)

        for socket in self.connectedSockets {
            socket.writeData(msgData, withTimeout: -1, tag: 0)
            socket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
        }
    }

    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        // This method is executed on the socketQueue (not the main thread)
        synchronize(self.connectedSockets) {
            self.connectedSockets.addObject(newSocket)
        }

        let host = newSocket.connectedHost
        let port:UInt16 = newSocket.connectedPort

        dispatch_async(dispatch_get_main_queue()) {
            // update some UI
            print("Accepted client connection \(host) : \(port)")
            NSNotificationCenter.defaultCenter().postNotificationName(HostManager.ConnectionEstablishedNotification, object: nil, userInfo: ["data": host])
        }

        let welcomeMsg = "Welcome to the AsyncSocket Echo Server\r\n";
        let welcomeData = welcomeMsg.dataUsingEncoding(NSUTF8StringEncoding)
        newSocket.writeData(welcomeData, withTimeout: -1, tag: WELCOME_MSG)
        newSocket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
    }

    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {

    }

    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        // This method is executed on the socketQueue (not the main thread)
        dispatch_async(dispatch_get_main_queue()) {
            let strData = data.subdataWithRange(NSMakeRange(0, data.length - 2))
            let msg = String(data: strData, encoding: NSUTF8StringEncoding)
            if let msg = msg {
                print(msg)
                NSNotificationCenter.defaultCenter().postNotificationName(HostManager.DataReceivedNotification, object: nil, userInfo: ["data": msg])
            } else {
                print("error converting received data")
            }
        }

        // Echo message back to client
        sock.writeData(data, withTimeout: -1, tag: ECHO_MSG)
    }

    /**
     * This method is called if a read has timed out.
     * It allows us to optionally extend the timeout.
     * We use this method to issue a warning to the user prior to disconnecting them.
     **/
    func socket(sock: GCDAsyncSocket!, shouldTimeoutReadWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        if elapsed <= READ_TIMEOUT {
            let warningMsg = "Are you still there?\r\n";
            let warningData = warningMsg.dataUsingEncoding(NSUTF8StringEncoding)
            sock.writeData(warningData, withTimeout: -1, tag: WARNING_MSG)

            return READ_TIMEOUT_EXTENSION;
        }
        return 0.0
    }

    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        if sock != listenSocket {
            dispatch_async(dispatch_get_main_queue()) {
                print("Client Disconnected")
            }

            synchronize(connectedSockets) {
                self.connectedSockets.removeObject(sock)
            }
        }
    }

    func synchronize<T>(lockObj: AnyObject!, closure: ()->T) -> T
    {
        objc_sync_enter(lockObj)
        let retVal: T = closure()
        objc_sync_exit(lockObj)
        return retVal
    }

}
