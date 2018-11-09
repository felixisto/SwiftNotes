
// https://github.com/krzyzanowskim/CryptoSwift
// installation:
// pod 'CryptoSwift' OR git submodule add https://github.com/krzyzanowskim/CryptoSwift.git
import CryptoSwift

let kSecClassValue = NSString(format: kSecClass)
let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
let kSecValueDataValue = NSString(format: kSecValueData)
let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
let kSecAttrServiceValue = NSString(format: kSecAttrService)
let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
let kSecReturnDataValue = NSString(format: kSecReturnData)
let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)

class LoginKeychain : NSObject
{
    class func updatePassword(service: String, account:String, password: String)
    {
        if let dataFromString: Data = password.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            
            // Instantiate a new default keychain query
            let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, kCFBooleanTrue, kSecMatchLimitOneValue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])
            
            let status = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueDataValue:dataFromString] as CFDictionary)
            
            if (status != errSecSuccess) {
                if let err = SecCopyErrorMessageString(status, nil) {
                    print("LoginKeychain: read failed: \(err)")
                }
            }
        }
    }
    
    class func removePassword(service: String, account:String)
    {
        
        // Instantiate a new default keychain query
        let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, kCFBooleanTrue, kSecMatchLimitOneValue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])
        
        // Delete any existing items
        let status = SecItemDelete(keychainQuery as CFDictionary)
        if (status != errSecSuccess) {
            if let err = SecCopyErrorMessageString(status, nil) {
                print("LoginKeychain: remove failed: \(err)")
            }
        }
        
    }
    
    class func savePassword(service: String, account:String, password: String)
    {
        if let dataFromString = password.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            
            // Instantiate a new default keychain query
            let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, dataFromString], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecValueDataValue])
            
            // Add the new keychain item
            let status = SecItemAdd(keychainQuery as CFDictionary, nil)
            
            if (status != errSecSuccess) {    // Always check the status
                if let err = SecCopyErrorMessageString(status, nil) {
                    print("LoginKeychain: write failed: \(err)")
                }
            }
        }
    }
    
    class func loadPassword(service: String, account:String) -> String?
    {
        // Instantiate a new default keychain query
        // Tell the query to return a result
        // Limit our results to one item
        let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, kCFBooleanTrue, kSecMatchLimitOneValue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])
        
        var dataTypeRef :AnyObject?
        
        // Search for the keychain items
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        var contentsOfKeychain: String?
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                contentsOfKeychain = String(data: retrievedData, encoding: String.Encoding.utf8)
            }
        }
        
        return contentsOfKeychain
    }
}

enum AESEncryptionError : Error
{
    case invalidKeyLength
    case invalidIVLength
}

class AESEncryption
{
    static let validKeyLengths = [32, 24, 16]
    
    // Given key length determines the AES encryption type.
    // A key of 32 chars and IV of 16 chars will mean the encryption will be AES 256bit
    class func encrypt(message: String, withKey key: String, withIV iv: String) throws -> String?
    {
        guard validKeyLengths.contains(key.count) else {
            throw AESEncryptionError.invalidKeyLength
        }
        
        do
        {
            let encrypted = try AES(key: key, iv: iv, padding: .pkcs7).encrypt([UInt8](message.data(using: .utf8)!))
            
            return Data(encrypted).base64EncodedString()
        }
        catch
        {
            return nil
        }
    }
    
    class func decrypt(encrypedMessage data: String, withKey key: String, withIV iv: String) throws -> String?
    {
        do
        {
            guard let data = Data(base64Encoded: data) else {
                return nil
            }
            
            let decrypted = try AES(key: key, iv: iv, padding: .pkcs7).decrypt([UInt8](data))
            
            return String(bytes: Data(decrypted).bytes, encoding: .utf8)
        }
        catch
        {
            return nil
        }
    }
}

class SaltHash
{
    static let SALT = "x4vV8bGgqqmQwgCoyXFQj+(o.nUNQhVP7ND"
    static let UNIQUE_SALT_OFFSET : UInt = 4
    
    class func generate(value: UInt) -> String
    {
        var uniqueSalt = ""
        
        var characterIndex : Int = 0
        
        let end = value + SaltHash.UNIQUE_SALT_OFFSET
        
        for _ in 0...end
        {
            if characterIndex >= SALT.count
            {
                characterIndex = 0
            }
            
            uniqueSalt.append(SALT[String.Index(encodedOffset: characterIndex)])
            
            characterIndex += 1
        }
        
        return uniqueSalt
    }
}

class SHA256Hashing
{
    class func hashSHA256(_ data: String) -> String
    {
        return data.sha256()
    }
    
    class func userPassHash(from name: String, password: String, salt: String) -> String
    {
        return hashSHA256("\(password).\(name).\(salt)")
    }
}
