import Foundation
import Postbox
import SwiftSignalKit

public struct ContactSynchronizationSettings: Equatable, PreferencesEntry {
    public var synchronizeDeviceContacts: Bool
    
    public static var defaultSettings: ContactSynchronizationSettings {
        return ContactSynchronizationSettings(synchronizeDeviceContacts: true)
    }
    
    public init(synchronizeDeviceContacts: Bool) {
        self.synchronizeDeviceContacts = synchronizeDeviceContacts
    }
    
    public init(decoder: PostboxDecoder) {
        self.synchronizeDeviceContacts = decoder.decodeInt32ForKey("synchronizeDeviceContacts", orElse: 0) != 0
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.synchronizeDeviceContacts ? 1 : 0, forKey: "synchronizeDeviceContacts")
    }
    
    public func isEqual(to: PreferencesEntry) -> Bool {
        if let to = to as? ContactSynchronizationSettings {
            return self == to
        } else {
            return false
        }
    }
}

func updateContactSynchronizationSettingsInteractively(postbox: Postbox, _ f: @escaping (ContactSynchronizationSettings) -> ContactSynchronizationSettings) -> Signal<Void, NoError> {
    return postbox.transaction { transaction -> Void in
        transaction.updatePreferencesEntry(key: ApplicationSpecificPreferencesKeys.contactSynchronizationSettings, { entry in
            let currentSettings: ContactSynchronizationSettings
            if let entry = entry as? ContactSynchronizationSettings {
                currentSettings = entry
            } else {
                currentSettings = .defaultSettings
            }
            return f(currentSettings)
        })
    }
}
