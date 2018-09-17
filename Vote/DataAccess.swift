import Foundation


public enum ResponseCompletion {
    case success(NSDictionary)
    case error(Error)
}

public class API {
    
    // MARK: - Singleton
    public static let shared = API()
    private init() {}
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    private func request(urlString: String, body: [String: AnyObject]) -> URLRequest  {
        let requestBody     = self.printPrettyBody(body: body) ?? ""
        
        guard let url       = URL(string: urlString) else { fatalError("CAN'T CREATE URL") }
        var request         = URLRequest(url: url)
        request.httpMethod  = "POST"
        request.httpBody    = requestBody.data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        #if DEBUG
        print("\n✂︎----------------------------------------------------------")
        print("From API URL: \(request.url!.absoluteString)")
        print("Request Body: \(requestBody)")
        print("----------------------------------------------------------✂︎\n")
        #endif
        
        return request
    }
    
    
    func fetch(url: String, body: [String: AnyObject], completion: @escaping (ResponseCompletion) -> Void) {
        var urlRequest = request(urlString: url, body: body)

            defaultSession.dataTask(with: urlRequest) { data, response, error in
            defer { self.dataTask = nil }
            
            if let error = error {
                completion(.error(error))
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                do {
                    let myData = try self.jsonToDic(data)
                    completion(.success(myData))
                }catch let er {
                    print("error: ", er.localizedDescription)
                    completion(.error(er))
                }
            }
        }.resume()
        
    }
    
}

extension API {
    
    private func printPrettyBody(body: [String: AnyObject]) -> String? {
        return self.JSONStringify(
            value           : body,
            prettyPrinted   : true
        )
    }
    
    private func encode(_ string: String) -> String? {
        let allowedCharacterSets = (NSCharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSets.removeCharacters(in: "!@#$%^&*()-_+=~`:;\"'<,>.?/")
        
        guard let encodeString = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSets as CharacterSet) else{
            return nil
        }
        
        return encodeString
    }
    
    private func JSONStringify(value: Any, prettyPrinted: Bool = false) -> String {
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : nil
        
        if JSONSerialization.isValidJSONObject(value) {
            if let data = try? JSONSerialization.data(withJSONObject: value, options: options!) {
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            }
        }
        
        return ""
    }
    
    private func jsonToDic(_ data: Data) throws -> NSDictionary{
        enum JSONError: Error {
            case serializedJSONError // dic -> JSON
            case deserializedJSONError
        }
        
        guard let dic: NSDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary else{
            throw JSONError.deserializedJSONError
        }
        
        print("dic", dic)
        
        return dic
    }
    
    private func dicToJSONString(_ dic: [String:AnyObject]) throws -> String{
        guard let data:Data = try? JSONSerialization.data(withJSONObject: dic, options: JSONSerialization.WritingOptions(rawValue: 0)) else{
            throw JSONError.serializedJSONError
        }
        guard let jsonString: String = String(data: data, encoding: String.Encoding.utf8) else{
            throw DataError.invalidEncodingData
        }
        return jsonString
    }
    
    private func jsonStringToDic(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

enum JSONError: Error {
    case serializedJSONError
    case deserializedJSONError
}
enum DataError: Error {
    case invalidEncodingData
}
