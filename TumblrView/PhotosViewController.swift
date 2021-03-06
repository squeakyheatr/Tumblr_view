//
//  PhotosViewController.swift
//  TumblrView
//
//  Created by Robert Mitchell on 2/8/17.
//  Copyright © 2017 Robert Mitchell. All rights reserved.
//

import UIKit
import AFNetworking


class PhotosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
  
    @IBOutlet var PhotoTableView: UITableView!
    
    var posts: [NSDictionary] = []
    
    var isLoadingMoreData: Bool = false
    
    var isLoadingMoreView: InfiniteScrollActivityView?
    
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PhotoTableView.delegate = self
        PhotoTableView.dataSource = self
        PhotoTableView.rowHeight = 240
        

        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(
            with: request as URLRequest,
            completionHandler: { (data, response, error) in
                if let data = data {
                    if let responseDictionary = try! JSONSerialization.jsonObject(
                        with: data, options:[]) as? NSDictionary {
                        //print("responseDictionary: \(responseDictionary)")
                        
                        // Recall there are two fields in the response dictionary, 'meta' and 'response'.
                        // This is how we get the 'response' field
                        let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                        
                        self.posts = responseFieldDictionary["posts"] as! [NSDictionary]

                    }
                }
                self.PhotoTableView.reloadData()
        });
        task.resume()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: .valueChanged)
        PhotoTableView.insertSubview(refreshControl, at: 0)
        let frame = CGRect(x: 0, y: PhotoTableView.contentSize.height, width: PhotoTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        isLoadingMoreView = InfiniteScrollActivityView(frame: frame)
        isLoadingMoreView!.isHidden = true
        PhotoTableView.addSubview(isLoadingMoreView!)
        
        var insets = PhotoTableView.contentInset
        insets.bottom += InfiniteScrollActivityView.defaultHeight
        PhotoTableView.contentInset = insets
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count ?? 0
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell") as! PhotoCell
       

        let post = posts[indexPath.row]
        if (post.value(forKeyPath: "photos") as? [NSDictionary]) != nil {
            let photos = post.value(forKeyPath: "photos") as? [NSDictionary]
            let imageUrlString = photos?[0].value(forKeyPath: "original_size.url") as? String
            let imageUrl = URL(string: imageUrlString!)!
            if let photos = post.value(forKeyPath: "photos") as? [NSDictionary] {
                
                cell.ImageCell.setImageWith(imageUrl as! URL)
                
            } else {
                // photos is nil. Good thing we didn't try to unwrap it!
            }

        } else {

        }
        

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PhotoTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func refreshControlAction(_ refreshControl: UIRefreshControl){
        
        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            self.PhotoTableView.reloadData()
            refreshControl.endRefreshing()
        }
        task.resume()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (!isLoadingMoreData) {
            let scrollViewContentHeight = PhotoTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - PhotoTableView.bounds.size.height
            
            if(scrollView.contentOffset.y > scrollOffsetThreshold && PhotoTableView.isDragging){
                isLoadingMoreData = true
                let frame = CGRect(x: 0, y: PhotoTableView.contentSize.height, width: PhotoTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                isLoadingMoreView?.frame = frame
                isLoadingMoreView!.startAnimating()
                loadMoreData()
            }
        }
        
    }
    
    func loadMoreData(){
        
        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            self.isLoadingMoreData = false
            self.isLoadingMoreView!.stopAnimating()
            self.PhotoTableView.reloadData()
        }
        task.resume()
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UITableViewCell
        var indexpath = PhotoTableView.indexPath(for: cell)
        let post = posts[(indexpath?.row)!]
        
        let detailVC = segue.destination as! PhotoDetailViewController
        
        detailVC.post = post
        
        
    }
    

}
