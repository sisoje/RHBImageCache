# RHBImageCache

Caching images from URLs and setting them directly to ```UIImageView```

There is ```UIImageView``` extension so you can make code like this:

{% gist 9f29fe20d89e1c30e0572449692bab74 %}
           
You have to keep the ```imageSetter``` reference alive as long as you want given URLimage to be loaded.

Once the reference is gone then the task is cancelled and image will not be set to image view.

Only one URL request will be sent even if more images share the same URL!
