
import Foundation

@Observable
class TrainNetworkClient{
 
    func getTrainData(){
        let request = URLRequest(url: URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-g")!)
       print(request)
        
    }

}

