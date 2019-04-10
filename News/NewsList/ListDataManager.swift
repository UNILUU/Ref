//
//  ListDataManager.swift
//  News
//
//  Created by Xiaolu Tian on 3/28/19.
//

import Foundation
import UIKit


protocol ListDataManagerDelegate : class{
    func dataHasUpdated(needRefresh: Bool)
}

class ListDataManager {
    static let shared = ListDataManager()
    let listLoader = NewsListLoader.shared
    let imageLoader = ImageLoader.shared
    private var newsMap : [String: News]
    private var newsViewModel : [String: NewsViewModel]
    private var moreNews : [NewsID]
    private var thumbnailCache = NSCache<NSString, UIImage>()
    
    var sortedList : [NewsViewModel]{
        didSet{
            delegate?.dataHasUpdated(needRefresh: true)
        }
    }
    
    weak var delegate : ListDataManagerDelegate?
    private init(){
        newsMap = [String: News]()
        newsViewModel = [String: NewsViewModel]()
        sortedList = [NewsViewModel]()
        moreNews = [NewsID]()
        loadModelFromDisk()
        
    }
    
    func loadModelFromDisk() {
        if let res = Storage.retrieve("Model", from: .cachesDirectory, as: [News].self ){
            self.mergeNewList(res)
        }

    }
}

// MARK:  load list
extension ListDataManager{
    func fetchNewList(){
        listLoader.loadNewList(20) { (result) in
            if case .success(let res) = result{
                self.mergeNewList(res.items.result)
                self.mergeMore(res.more.result)
            }
        }
    }
    
    func fetchMoreData(){
        var i = 0
        var ids = [String]()
        while i < moreNews.count && i < 10{
            ids.append(moreNews.removeFirst().uuid)
            i += 1
        }
        listLoader.fetchMore(ids) { (result) in
            if case .success(let res) = result {
                self.mergeNewList(res.items.result)
            }
        }
    }
    
    
    func getNewViewModelFor(_ index: IndexPath) -> NewsViewModel {
        return sortedList[index.row]
    }
    
}

// MARK: - Fetch Image
extension ListDataManager{
    func getImageFor(_ index : IndexPath, completion: @escaping (UIImage? ) -> Void){
        guard let urlString = sortedList[index.row].thumbnailURL, let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        let filename = String(url.lastPathComponent.split(separator: ".")[0] + "_full")
        
        //Find in cache
        if let image = thumbnailCache.object(forKey: urlString as NSString){
            DispatchQueue.main.async {
                completion(image)
            }
            return
        }
        //Check disk
        if let image = UIImage.getImageFrom(directory: .cachesDirectory, name: filename){
            thumbnailCache.setObject(image, forKey: urlString as NSString)
            print("got image from disk \(filename)")
            DispatchQueue.main.async {
                completion(image)
            }
            return
        }
        
        //download
        imageLoader.downloadImage(url) { [weak self] (result) in
            if case .success(let image) = result {
                DispatchQueue.main.async {
                    completion(image)
                }
                //save image to disk
                try? image.save(directory: .cachesDirectory, name: filename)
                self?.thumbnailCache.setObject(image, forKey: urlString as NSString)
            }else {
                completion(nil)
            }
        }
    }
    
    func cancelTask(_ index: IndexPath){
        guard sortedList.count > index.row ,let url = sortedList[index.row].thumbnailURL else {
            return
        }
        imageLoader.cancelTask(imageURL: url)
    }
    
    
}


// MARK: - merge data
extension ListDataManager{
    private func mergeNewList(_ responselist : [News]) {
        var hasChange = false
        for news in responselist{
            if let _ = newsMap[news.uuid]{
                if news != newsMap[news.uuid]! {   //data updated from server
                    newsMap[news.uuid] = news
                    newsViewModel[news.uuid] = NewsViewModel(news)
                    hasChange = true
                }
            }else{
                // new data
                newsMap[news.uuid] = news
                newsViewModel[news.uuid] = NewsViewModel(news)
                hasChange = true
            }
        }
        if hasChange{
            Storage.store(Array(newsMap.values), to: .cachesDirectory , as: "Model")
            sortedList = newsViewModel.values.sorted(by: >)
        }else{
            delegate?.dataHasUpdated(needRefresh: false)
        }
    }
    
    private func mergeMore(_ response : [NewsID]){
        for id in response{
            
            if !moreNews.contains(id) && newsMap[id.uuid] == nil{
                moreNews.append(id)
            }
        }
    }
}

