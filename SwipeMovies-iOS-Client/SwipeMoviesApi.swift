import UIKit

class SwipeMoviesApi {
    
    private static var instance: SwipeMoviesApi?
    private var user: User?
    
    private init() {
        user = User(0, "Test")
    }

    public static func getInstance() -> SwipeMoviesApi {
        if instance === nil {
            instance = SwipeMoviesApi()
        }
        
        return instance!
    }
    
    public func createGroup(_ name: String, _ callback: @escaping (_ group: Group) -> Void) {
        if let url = URL(string: "\(getBackendUrl())/api/groups") {
            let json: [String: Any] = [
                "name": name
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: json) {
                var request = URLRequest(url: url)
                
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                request.httpMethod = "POST"
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, _, _) -> Void in
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        let group = Group(json["id"] as! Int, json["name"] as! String)
                        callback(group)
                    }
                })
                task.resume()
            }
        }
    }
    
    public func joinGroup(_ id: Int, _ callback: @escaping () -> Void) {
        if let user = user, let url = URL(string: "\(getBackendUrl())/api/users/\(user.id)/groups") {
            let json: [String: Any] = [
                "id": id
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: json) {
                var request = URLRequest(url: url)
                
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                request.httpMethod = "POST"
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request, completionHandler: { (_, _, _) -> Void in
                    callback()
                })
                task.resume()
            }
        }
    }
    
    public func getGroups(_ callback: @escaping (_ groups: [Group]) -> Void) {
        var groups: [Group] = []
        
        if let user = user, let url = URL(string: "\(getBackendUrl())/api/users/\(user.id)/groups") {
            if let data = try? Data(contentsOf: url) {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []), let array = json as? [Any] {
                    for obj in array {
                        if let dict = obj as? [String: Any] {
                            let group = Group(dict["id"] as! Int, dict["name"] as! String)
                            groups.append(group)
                        }
                    }
                    
                    callback(groups)
                }
            } else {
                print("Download failed")
            }
        } else {
            print("Cannot resolve URL")
        }
    }
    
    public func postSwipedMovie(_ swipedMovie: SwipedMovie) {
        if let user = user, let url = URL(string: "\(getBackendUrl())/api/users/\(user.id)/movies/swiped") {
            let json: [String: Any] = [
                "movie": [
                    "id": swipedMovie.movie.id,
                    "title": swipedMovie.movie.title,
                    "description": swipedMovie.movie.description,
                    "posterUrl": swipedMovie.movie.posterUrl
                ],
                "swipeDirection": swipedMovie.swipeDirection == .right ? "right" : "left"
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: json) {
                var request = URLRequest(url: url)
                
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                request.httpMethod = "POST"
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request)
                task.resume()
            }
        }
    }
    
    public func getMovies(_ callback: @escaping (_ movies: [Movie]) -> Void) {
        if let user = user, let url = URL(string: "\(self.getBackendUrl())/api/users/\(user.id)/movies") {
            if let data = try? Data(contentsOf: url) {
                if let movieArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                    var movies: [Movie] = []
                    
                    for movie in movieArray {
                        if let dict = movie as? [String: Any] {
                            let id = dict["id"] as! Int
                            let title = dict["title"] as! String
                            let description = dict["description"] as! String
                            let posterUrl = dict["posterUrl"] as! String
                            
                            movies.append(Movie(id, title, description, posterUrl))
                        }
                    }
                    
                    callback(movies)
                }
            } else {
                print("Download failed")
            }
        }
    }
    
    public func getMatches(_ callback: @escaping (_ matches: [Match]) -> Void) {
        var matches: [Match] = []
        
        if let user = user, let url = URL(string: "\(getBackendUrl())/api/users/\(user.id)/matches") {
            if let data = try? Data(contentsOf: url) {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []), let array = json as? [Any] {
                    for obj in array {
                        if let dict = obj as? [String: Any] {
                            if let movie = dict["movie"] as? [String: Any] {
                                let match = Match(Movie(movie["id"] as! Int, movie["title"] as! String, movie["description"] as! String, movie["posterUrl"] as! String))
                                
                                if let users = dict["users"] as? [Any] {
                                    for userObj in users {
                                        if let user = userObj as? [String: Any] {
                                            match.addUser(User(user["id"] as! Int, user["username"] as! String))
                                        }
                                    }

                                    matches.append(match)
                                }
                            }
                        }
                    }
                    
                    callback(matches)
                }
            } else {
                print("Download failed")
            }
        } else {
            print("Cannot resolve URL")
        }
    }
    
    private func getBackendUrl() -> String {
        return Bundle.main.infoDictionary?["Backend URL"] as! String
    }

}
