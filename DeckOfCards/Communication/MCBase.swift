import Foundation
import MultipeerConnectivity

protocol ColorServiceManagerDelegate {

    func connectedDevicesChanged(manager : ColorServiceManager, connectedDevices: [String])
    func colorChanged(manager : ColorServiceManager, colorString: String)

}

enum QuitReason {
    case NoNetwork,          // no Wi-Fi or Bluetooth
    ConnectionDropped,  // communication failure with server
    UserQuit,           // the user terminated the connection
    ServerQuit         // the server quit the game (on purpose)
}

class ColorServiceManager : NSObject {

    static let serviceType = "deck-of-cards"
    static let peerId = MCPeerID(displayName: UIDevice.currentDevice().name)

    lazy var session: MCSession = {
        let session = MCSession(peer: ColorServiceManager.peerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        return session
    }()

//    func sendColor(colorName : String) {
//        NSLog("%@", "sendColor: \(colorName)")
//
//        if session.connectedPeers.count > 0 {
//            var error : NSError?
//            do {
//                try self.session.sendData(colorName.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
//            } catch let error1 as NSError {
//                error = error1
//                NSLog("%@", "\(error)")
//            }
//        }
//
//    }

}

extension MCSessionState {

    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "NotConnected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
        }
    }
}

extension ColorServiceManager : MCSessionDelegate {

    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
//        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))

        // the nearby peer declined the invitation, the connection could not be established, 
        // or a previously connected peer is no longer connected

    }

    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data.length) bytes")
        let str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
//        self.delegate?.colorChanged(self, colorString: str)
    }

    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }

    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }

    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }

}