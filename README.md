# RHBImageCache

Caching images from URLs and setting them directly to ```UIImageView```

There is ```UIImageView``` extension so you can write:

            self.imageSetter = self.imageView.setCachedImage(url: imageUrl)
            
            
You have to keep the ```imageSetter``` reference alive as long as you want given URLimage to be loaded.

Once the reference is gone then the task is cancelled and image will not be set to image view.

Only one URL request will be sent even if more images share the same URL!
