import Quick
import Nimble
import Clappr

class EventHandlerSpec: QuickSpec {
    override func spec() {
        describe("EventHandler") {
            
            it("Should receive the user info back") {
                var control: String!
                let info = "result"
                
                let eventHandler = EventHandler(callback: { (userInfo) -> () in
                    let userInfo = userInfo as! [String: String]
                    control = userInfo["testCase"]
                })
                
                eventHandler.handleEvent(NSNotification(name: NSNotification.Name(rawValue: ""), object: self, userInfo: ["testCase": info]) as Notification)
                
                expect(control) == info
            }
        }
    }
}
