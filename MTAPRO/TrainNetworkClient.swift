//
//import Foundation
//
//@Observable
//class TrainNetworkClient {
//    private let session: URLSession
//    private let baseURL = URL(string: "https://api-endpoint.mta.info")!
//    
//    
//    init(session: URLSession = .shared, apiKey: String? = nil) {
//        self.session = session
//    }
//    
//    func getTrainData() async throws -> Data {
//        // Construct the full URL
//        let url = baseURL.appendingPathComponent("Dataservice/mtagtfsfeeds/nyct%2Fgtfs-g")
//        var request = URLRequest(url: url)
//        
//        
//        let (data, response) = try await session.data(for: request)
//        
//        // Basic HTTP status validation
//        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
//            throw URLError(.badServerResponse)
//        }
//        
//        return data
//    }
//}

