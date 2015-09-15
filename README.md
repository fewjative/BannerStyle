# BannerStyle
iOS jailbreak tweak that adds flair to notification banner animations.

How it works:

iOS has a method that gives the duration of the animation for showing and hiding banners. If we set this to 0, the banner will display immediately. However, it will also set the completion status of the presentation as completed. Thus, hook the duration method and return 0 and then hook the completion method and have a flag that disallows completion until we have unset the flag( -(void)completeTransition:(BOOL)b ). Once we have done this we are free to do anything, we can hide the banner offscreen and then use our own custom animations to bring it back. Because I only want to effect the presentation of the banner at this moment, I check the status of isPresenting(1 = presenting, 0 = hiding).

Example animation(transition banner type with cube style - welcome to iOS6): https://twitter.com/fewjative/status/643231860613517312/video/1

