import Foundation
import MultipeerConnectivity

enum QuitReason {
    case NoNetwork,          // no Wi-Fi or Bluetooth
    ConnectionDropped,  // communication failure with server
    UserQuit,           // the user terminated the connection
    ServerQuit         // the server quit the game (on purpose)
}

// https://www.hackingwithswift.com/example-code/system/how-to-create-a-peer-to-peer-network-using-the-multipeer-connectivity-framework

class MCNetworking: NSObject {

    let serviceType = "deck-of-cards"
    let peerId = MCPeerID(displayName: UIDevice.currentDevice().name)

    lazy var session: MCSession = {
        let session = MCSession(peer: self.peerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        return session
    }()
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