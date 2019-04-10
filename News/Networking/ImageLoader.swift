//
//  ImageLoader.swift
//  News
//
//  Created by Xiaolu Tian on 3/28/19.
//

import Foundation
import UIKit

class ImageLoader {
    static let shared = ImageLoader()
    var dict = [String: URLSessionDataTask]()
    
    private let session = URLSession.shared
    private init(){
    }
    
    func downloadImage(_ url : URL, _ completion : @escaping ( Result< UIImage, NewsError>) -> Void ){
        let task = URLSession.shared.dataTask(with: url) { [weak self](data, _, error) in
            guard error == nil, let data = data else {
                completion(.failure(.noDATA))
                self?.dict[url.absoluteString] = nil
                return
            }
            
            if let image = UIImage(data: data){
                DispatchQueue.main.async {
                    completion(Result.success(image))
                }
                self?.dict[url.absoluteString] = nil
            }else{
                completion(.failure(.errorParseData))
            }
        }
        task.resume()
        dict[url.absoluteString] = task
    }
    
    func cancelTask(imageURL : String){
        if let task = dict[imageURL]{
            task.cancel()
            dict[imageURL] = nil
        }
    }
}
