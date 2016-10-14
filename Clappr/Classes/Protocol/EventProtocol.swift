public protocol EventProtocol {
    @discardableResult
    func on(_ eventName:String, callback: @escaping EventCallback) -> String
    @discardableResult
    func once(_ eventName:String, callback: @escaping EventCallback) -> String
    func off(_ listenId: String)
    
    func trigger(_ eventName:String)
    func trigger(_ eventName:String, userInfo: [AnyHashable: Any]?)
    
    func listenTo<T: EventProtocol>(_ contextObject: T, eventName: String, callback: @escaping EventCallback) -> String
    func listenToOnce<T: EventProtocol>(_ contextObject: T, eventName: String, callback: @escaping EventCallback) -> String
    func stopListening()
    func stopListening(_ listenId: String)
    
    func getEventContextObject() -> BaseObject
}
