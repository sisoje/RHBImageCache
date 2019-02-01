# RHBImageCache

Caching images from URLs and setting them directly to ```UIImageView```

There is ```UIImageView``` extension so you can make code like this:

```
class URLImageTableViewCell: UITableViewCell {
    @IBOutlet weak var urlImageView: UIImageView!    
    
    var urlImageLoader: DeinitBlock?

    // new task is created, old task cancelled automatically
    func setImage(url: URL) {
        urlImageLoader = urlImageView.setCachedImage(url: url)
    }
}
```
URL requests are grouped by URL and cancelled automatically when needed
