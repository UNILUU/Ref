//
//  NewsListLoader.swift
//  News
//
//  Created by Xiaolu Tian on 3/28/19.
//

import Foundation

//enum Result<T>{
//    case failure
//    case success(T)
//}

enum NewsError : Error{
    case badURL
    case noDATA
    case errorParseData
}


class NewsListLoader {
    static let shared = NewsListLoader()
    
    private let session = URLSession.shared
    private init(){
    }

    func loadNewList(_ count : Int, _ completion : @escaping (Result<NewsListResponse, NewsError>) -> Void ){
        let urlPath = "https://doubleplay-sports-yql.media.yahoo.com/v3/sports_news?leagues=sports&stream_type=headlines&count=\(count)&region=US&lang=en-US"
        guard let url = URL(string:urlPath) else {
            completion(.failure(.badURL))
            return
        }

        let task = session.dataTask(with: url) { (data, _, error) in
            guard error == nil, let data = data else {
                completion(.failure(.noDATA))
                return
            }
            if let list = try? JSONDecoder().decode(NewsListResponse.self, from: data){
                completion(.success(list))
            }else{
                completion(.failure(.errorParseData))
            }
        }
        task.resume()
    }
    
    
    func fetchMore(_ ids : [String], _ completion : @escaping (Result<InflationResponse, NewsError>) -> Void ){
        let res  = ids.joined(separator: ",")
        let urlstr = "https://doubleplay-sports-yql.media.yahoo.com/v3/news_items?uuids=\(res)"
        guard let url = URL(string: urlstr) else {
             completion(.failure(.badURL))
            return
        }
        
        let task = session.dataTask(with: url) { (data, _, error) in
            guard error == nil, let data = data else {
                 completion(.failure(.noDATA))
                return
            }
            if let res = try? JSONDecoder().decode(InflationResponse.self, from: data) {
                completion(.success(res))
            }else{
                completion(.failure(.errorParseData))
            }
        }
        task.resume()
    }
}



