#import <substrate.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Quartzcore/Quartzcore.h>
//#include "InspCWrapper.m"
#include "MGFashionMenuView.h"

extern "C" UIImage * _UICreateScreenUIImage();

#define PERSPECTIVE_LAYER @"PERSPECTIVE_LAYER"
#define IS_ANIMATING @"IS_ANIMATING"

typedef enum {
    CubeTransitionDirectionUp,
    CubeTransitionDirectionDown
} CubeTransitionDirection;



@interface SBBannerContainerView : UIView
@end

@interface SBBannerContextView : UIView
-(CGRect)frame;
-(UIView*)_vibrantContentView;
-(UIView*)testBlur;
-(UIView*)backdrop;
@end

@interface SBDefaultBannerView : UIView
-(CGRect)_contentFrame;
-(CGRect)frame;
@end

@interface SBBannerController : UIViewController
-(UIViewController*)_bannerViewController;
@end

@interface SBBannerContainerViewController : UIViewController
-(CGFloat)transitionDuration:(id)tc;
-(UIView*)bannerContextView;
@end

@interface _SBBulletinRootViewControllerTransitionContext
-(UIView*)containerView;
-(SBBannerContainerViewController*)presentedViewController;
-(void)completeTransition:(BOOL)b;
-(BOOL)isPresenting;
-(void)setupAnimatedBanner;
-(void)setupTransitionBanner;
-(void)setupFashionMenuBanner;
-(void)displayAnimatedBanner;
-(void)displayStaticBanner:(NSInteger)val;
-(void)hideStaticBanner:(NSInteger)val;
-(void)hideTransitionBanner;
-(void)setupHidingTransitionBanner;
-(void)displayTransitionBanner;
-(void)displayFashionMenuBanner;
-(void)setupHidingMaterialBanner;
-(void)hideMaterialBanner;
-(UIImage*)rotateImage:(UIImage*)img byDegrees:(CGFloat)deg;
@end

@interface SBBulletinBannerController
-(id)sharedInstance;
+(void)_showTestBanner:(BOOL)val;
@end

@interface SBLockScreenManager
-(id)sharedInstance;
-(BOOL)isUILocked;
@end

@interface SBNotificationCenterController
-(id)sharedInstance;
-(BOOL)isVisible;
@end

@interface _UIBackdropView : UIView
@end

static UIView * animatedBanner = nil;
static UIView * transitionBanner = nil;
static UIView * containerBanner = nil;
static UIImageView * animatedBannerIV = nil;
static UIImageView * fromIV = nil;
static UIImageView * toIV = nil;
static UIImageView * background = nil;
static UIView * toView = nil;
static MGFashionMenuView * menuView = nil;
static SBBannerContainerView * container = nil;
static SBBannerContextView * bannerContext = nil;
static CGRect defaultIconFrame;
static _SBBulletinRootViewControllerTransitionContext * transitionContext = nil;
static BOOL displayingBanner = NO;
static BOOL inCompletion = NO;
static _UIBackdropView * backDrop = nil;
static BOOL preventRealCompletion = YES;
static BOOL isUILocked;
static BOOL isNotifVisible;

static BOOL enabled = NO;
static NSInteger incomingDirection = 0;
static NSInteger incomingBannerStyle = 0;
static NSInteger outgoingDirection = 0;
static NSInteger outgoingBannerStyle = 0;
static NSInteger materialBannerStyle = 0;
static BOOL allowLS = NO;
static BOOL allowNotif = NO;
static BOOL disableOut = NO;
static BOOL disableIn = NO;

%hook _SBBulletinRootViewControllerTransitionContext

-(void)cancelInteractiveTransition {
	%orig;
	NSLog(@"CancelIT");
}

-(void)completeTransition:(BOOL)b {

	NSLog(@"compTr: %ld", b);
	NSLog(@"bs: %d %d", incomingBannerStyle, outgoingBannerStyle);
	if(!enabled)
	{
		%orig;
	}
	else if(!allowLS && isUILocked)
	{
		%orig;
	}
	else if(!allowNotif && isNotifVisible)
	{
		%orig;
	}
	else if(incomingBannerStyle == 22 && [self isPresenting])
	{
		%orig;
	}
	else if(outgoingBannerStyle == 1 && ![self isPresenting])
	{
		%orig;
	}
	else if(preventRealCompletion)
	{
		if([self isPresenting])
		{
			if( incomingBannerStyle == 0)
			{
				[self displayStaticBanner:incomingDirection];
			}
			else if( incomingBannerStyle > 0 && incomingBannerStyle < 15)
			{
				[self setupTransitionBanner];
				[self displayTransitionBanner];
			}
			else if( incomingBannerStyle == 15)
			{
				[self setupAnimatedBanner];
				[self displayAnimatedBanner];
			}
			else if( incomingBannerStyle > 15)
			{
				[self setupFashionMenuBanner];
				[self displayFashionMenuBanner];
			}
		}
		else
		{
			if( outgoingBannerStyle == 0)
			{
				[self hideStaticBanner:outgoingDirection];
			}
			else if( outgoingBannerStyle == 1 )
			{
				[self setupHidingMaterialBanner];
				[self hideMaterialBanner];
			}

			//[self setupHidingTransitionBanner];
			//[self hideTransitionBanner];
		}
	}
	else
	{
		%orig;
		preventRealCompletion = YES;
	}
}

%new - (void)displayStaticBanner:(NSInteger)direction
{
	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];
	CGRect baseRect = contextView.frame;
	contextView.alpha = 1;

	switch (direction)
	{
		case 0:
		{
			contextView.frame = CGRectMake(-baseRect.size.width, baseRect.origin.y, baseRect.size.width, baseRect.size.height);
			break;
		}

		case 1:
		{
			contextView.frame = CGRectMake(baseRect.size.width, baseRect.origin.y, baseRect.size.width, baseRect.size.height);
			break;
		}

		case 2:
		{
			contextView.frame = CGRectMake(baseRect.origin.x, -baseRect.size.height, baseRect.size.width, baseRect.size.height);		
			break;
		}

		case 3:
		{
			contextView.frame = CGRectMake(baseRect.origin.x, [UIScreen mainScreen].bounds.size.height, baseRect.size.width, baseRect.size.height);
			break;
		}
	}

	[UIView animateWithDuration:0.40f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		contextView.frame = baseRect;
	}
	completion:^(BOOL finished) {
		preventRealCompletion = NO;
		[self completeTransition:YES];
	}];
}

%new - (void)hideStaticBanner:(NSInteger)direction
{
	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];
	contextView.alpha = 1;
	contextView.frame = CGRectMake(0,0,320,68);
	CGRect baseRect = contextView.frame;

	CGRect toRect = baseRect;

	switch (direction)
	{
		case 0:
		{
			toRect = CGRectMake(-baseRect.size.width, baseRect.origin.y * -1, baseRect.size.width, baseRect.size.height);
			break;
		}

		case 1:
		{
			toRect = CGRectMake(baseRect.size.width, baseRect.origin.y * -1, baseRect.size.width, baseRect.size.height);
			break;
		}

		case 2:
		{
			toRect = CGRectMake(baseRect.origin.x, -baseRect.size.height, baseRect.size.width, baseRect.size.height);
			break;
		}

		case 3:
		{
			toRect = CGRectMake(baseRect.origin.x, [UIScreen mainScreen].bounds.size.height, baseRect.size.width, baseRect.size.height);
			break;
		}
	}

	NSLog(@"brect: %@", NSStringFromCGRect(baseRect));
	NSLog(@"rect: %@", NSStringFromCGRect(toRect));
    [UIView setAnimationsEnabled:YES];
	[UIView animateWithDuration:0.40f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		contextView.frame = toRect;
	}
	completion:^(BOOL finished) {
		preventRealCompletion = NO;
		[self completeTransition:YES];
	}];
}

%new - (void)setupFashionMenuBanner {

	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];

	CGRect baseRect = CGRectMake(0,0, contextView.bounds.size.width,contextView.bounds.size.height);

	if(!animatedBanner)
		animatedBanner = [[UIView alloc] initWithFrame:baseRect];

	[animatedBanner addSubview:contextView];
	contextView.alpha = 1;

	menuView = [[MGFashionMenuView alloc] initWithMenuView:animatedBanner withStyle:incomingBannerStyle-16];

	[bcvc.view insertSubview:menuView atIndex:0];
}

%new - (void)displayFashionMenuBanner {
	  [menuView showWithCompletition:^{

	  		SBBannerContainerViewController * bcvc = [self presentedViewController];
			SBBannerContextView * contextView = [bcvc bannerContextView];
			[bcvc.view addSubview:contextView];
			animatedBanner = nil;
	  		[menuView removeFromSuperview];
	  		menuView = nil;
  			preventRealCompletion = NO;
			[self completeTransition:YES];
	  }];
}

%new - (void)setupAnimatedBanner {

	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];
	SBDefaultBannerView * defaultBanner = [contextView _vibrantContentView];
	NSLog(@"Context: %@", contextView);
	CGRect baseRect = CGRectMake(0,0, contextView.bounds.size.width,contextView.bounds.size.height);

	if(!animatedBanner)
		animatedBanner = [[UIView alloc] initWithFrame:baseRect];

	animatedBanner.alpha = 0.3;
	contextView.alpha = 1;
	[animatedBanner addSubview:contextView];

	//Hide everything but the banner backdrop
	defaultBanner.alpha = 0;
	UIView * grabber = MSHookIvar<UIView*>(contextView, "_grabberView");
	grabber.alpha = 0;

	if(!animatedBannerIV)
		animatedBannerIV = [[UIImageView alloc] init];

	[animatedBanner addSubview:animatedBannerIV];

	UIImageView  * iconImageView = MSHookIvar<UIImageView*>(defaultBanner,"_iconImageView");
	CGRect oldFrame = [iconImageView frame];

	if(!CGRectEqualToRect(contextView.frame,defaultBanner.frame))
	{
		CGRect currentFrame = [defaultBanner _contentFrame];
		CGFloat half = baseRect.size.width/2;
		CGFloat start = half - currentFrame.size.width/2;
		defaultIconFrame = CGRectMake(start, oldFrame.origin.y, oldFrame.size.width, oldFrame.size.height);
	}
	else
		defaultIconFrame = oldFrame;

	CGRect centerRect = CGRectMake(baseRect.size.width/2 - oldFrame.size.width/2, baseRect.size.height/2 - oldFrame.size.height/2, oldFrame.size.width, oldFrame.size.height);
	NSLog(@"centerRect: %@", NSStringFromCGRect(centerRect));
	animatedBannerIV.frame = centerRect;
	animatedBannerIV.image = [iconImageView image];

	[bcvc.view insertSubview:animatedBanner atIndex:0];
}

%new -(void)displayAnimatedBanner {

	NSLog(@"Displaying banner");

	CGRect maskRect = CGRectMake(animatedBanner.bounds.size.width/2 - animatedBanner.bounds.size.height/2, 0, animatedBanner.bounds.size.height, animatedBanner.bounds.size.height);
	NSLog(@"Mask Rect: %@", NSStringFromCGRect(maskRect));

	CAShapeLayer * layerMask = [CAShapeLayer layer];
	layerMask.fillColor = [UIColor blackColor].CGColor;
	CGMutablePathRef path = CGPathCreateMutable();

	if( materialBannerStyle == 0 ) //circle
	{
		layerMask.path = [UIBezierPath bezierPathWithRoundedRect:maskRect cornerRadius:animatedBanner.bounds.size.height].CGPath;
	}
	else if (materialBannerStyle == 1) //square
	{
		layerMask.path = [UIBezierPath bezierPathWithRect:maskRect].CGPath;
	} 
	else if (materialBannerStyle == 2) //diamond
	{
		CGPathMoveToPoint(path, nil, maskRect.origin.x + maskRect.size.width/2, maskRect.origin.y);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x + maskRect.size.width, maskRect.size.height/2);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x + maskRect.size.width/2, maskRect.size.height);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x, maskRect.size.height/2);
		CGPathCloseSubpath(path);
		layerMask.path = path;
	}
	else if (materialBannerStyle == 3) //triangle
	{
		CGPathMoveToPoint(path, nil, maskRect.origin.x + maskRect.size.width/2, maskRect.origin.y);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x + maskRect.size.width, maskRect.size.height);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x, maskRect.size.height);
		CGPathCloseSubpath(path);
		layerMask.path = path;

		//need to change imageview to center of triangle
	}
	else if (materialBannerStyle == 4) //star
	{

	}

	layerMask.anchorPoint = CGPointMake(0.5,0.5);
	layerMask.frame = maskRect;
	layerMask.bounds = animatedBanner.bounds;
	animatedBanner.layer.mask = layerMask;
	animatedBanner.transform = CGAffineTransformMakeScale(0.1,0.1);

	[UIView setAnimationsEnabled:YES];
	[UIView animateWithDuration:0.30 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.0f options:0 animations:^{
		animatedBanner.transform = CGAffineTransformMakeScale(0.8,0.8);
		animatedBanner.alpha = 1;
	} completion:^(BOOL completed){

		if(completed)
		{
			NSLog(@"Completed animation 1");
			animatedBanner.transform = CGAffineTransformIdentity;
			animatedBanner.layer.transform = CATransform3DIdentity;
			
			CGPathRelease(path);

			CGFloat pct = 12;
			[CATransaction begin];
			layerMask.transform = CATransform3DIdentity;
			layerMask.anchorPoint = CGPointMake(0.5,0.5);
			layerMask.frame = animatedBanner.frame;
			layerMask.transform = CATransform3DMakeScale(0.8, 0.8, 1);
			NSLog(@"center: %@", NSStringFromCGPoint(animatedBanner.layer.position));

			CABasicAnimation * anim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
			CATransform3D tr = CATransform3DIdentity;
			tr = CATransform3DScale(tr, 9, 9, 1);
			anim.toValue = [NSValue valueWithCATransform3D:tr];
			anim.removedOnCompletion = NO;
			anim.duration = 0.24f;
			anim.fillMode = kCAFillModeForwards;
			anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
			[CATransaction setCompletionBlock:^{
				
			}];

			[animatedBanner.layer.mask addAnimation:anim forKey:@"scale"];
			[CATransaction commit];

			/*return;
			preventRealCompletion = NO;
			[self completeTransition:YES];*/

			[UIView animateWithDuration:0.30f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
				animatedBannerIV.frame = defaultIconFrame;
			}
			completion:^(BOOL finished) {
				NSLog(@"center: %@", NSStringFromCGPoint(layerMask.position));
				
				SBBannerContainerViewController * bcvc = [self presentedViewController];
				SBBannerContextView * contextView = [bcvc bannerContextView];

				[bcvc.view addSubview:contextView];
				[contextView _vibrantContentView].alpha = 1;
				UIView * grabber = MSHookIvar<UIView*>(contextView, "_grabberView");
				grabber.alpha = 1;

				[animatedBanner removeFromSuperview];
				animatedBanner = nil;
				preventRealCompletion = NO;
				[self completeTransition:YES];
			}];
		}
	}];
}

%new - (void)setupTransitionBanner {

	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];
	CGRect baseRect = contextView.frame;

	//We need a container for the banner because we want to have a black
	//background for when a 3D transition effect is applied
	containerBanner = [[UIView alloc] initWithFrame:baseRect];
	containerBanner.backgroundColor = [UIColor blackColor];

	transitionBanner = [[UIView alloc] initWithFrame:baseRect];
	transitionBanner.layer.masksToBounds = YES;

	toView = [[UIView alloc] initWithFrame:baseRect];

	// Background will contain a picture of the current banner area(similar to fromIV below).
	// It isn't necessary here but keeping it in case I do want to use it
	// and don't want to rewrite the code.
	//background = [[UIImageView alloc] initWithFrame:baseRect];
	//[toView addSubview:background];

	[toView addSubview:contextView];
	contextView.alpha = 1;

	if([contextView respondsToSelector:@selector(testBlur)])
	{
		//Using [UIScreen mainScreen].scale as the scale value makes the backdrop half visible. Why???
		[contextView testBlur].layer.shouldRasterize = YES;
		[contextView testBlur].layer.rasterizationScale = 1.5;
	}
	else
	{
		[contextView backdrop].layer.shouldRasterize = YES;
		[contextView backdrop].layer.rasterizationScale = 1.5;
	}


	UIImage * currentScreen =  _UICreateScreenUIImage();

	// fromIV is just a snapshot of the current banner area(no banner is currently visible)
	fromIV = [[UIImageView alloc] initWithFrame:baseRect];
	fromIV.contentMode = UIViewContentModeTopLeft;
	fromIV.clipsToBounds = YES;

	NSInteger orientation = [UIDevice currentDevice].orientation;

	NSLog(@"orientation: %d %@ %@ %@",orientation, fromIV, NSStringFromCGPoint(fromIV.center), currentScreen);

	if (orientation == 1 || orientation == 2)
	{
		fromIV.image = currentScreen;
	}
	else
	{
		UIImage * rotated = [self rotateImage:currentScreen byDegrees:270];
		fromIV.image = rotated;
	}

	//background.image = curentScreen;
	//background.contentMode = UIViewContentModeTopLeft;
	//background.clipsToBounds = YES;
	//[background release];
	
	[transitionBanner addSubview:fromIV];
	[containerBanner addSubview:transitionBanner];
	[bcvc.view insertSubview:containerBanner atIndex:0];
}

%new - (void)setupHidingTransitionBanner {

	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];
	CGRect baseRect = contextView.frame;

	//We need a container for the banner because we want to have a black
	//background for when a 3D transition effect is applied
	containerBanner = [[UIView alloc] initWithFrame:baseRect];
	containerBanner.backgroundColor = [UIColor blackColor];

	transitionBanner = [[UIView alloc] initWithFrame:baseRect];
	transitionBanner.layer.masksToBounds = YES;

	contextView.alpha = 1;

	/*if([contextView respondsToSelector:@selector(testBlur)])
	{
		//Using [UIScreen mainScreen].scale as the scale value makes the backdrop half visible. Why???
		[contextView testBlur].layer.shouldRasterize = YES;
		[contextView testBlur].layer.rasterizationScale = 1.5;
	}
	else
	{
		[contextView backdrop].layer.shouldRasterize = YES;
		[contextView backdrop].layer.rasterizationScale = 1.5;
	}*/
	
	[transitionBanner addSubview:contextView];
	[containerBanner addSubview:transitionBanner];
	[bcvc.view insertSubview:containerBanner atIndex:0];
}

%new - (UIImage*)rotateImage:(UIImage*)img byDegrees:(CGFloat)val {
		UIView * rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,img.size.width,img.size.height)];
		float angleRadians = val * ((float)M_PI/180.0f);
		CGAffineTransform t = CGAffineTransformMakeRotation(angleRadians);
		rotatedViewBox.transform = t;
		CGSize rotatedSize = rotatedViewBox.frame.size;

		rotatedViewBox = nil;
		
		UIGraphicsBeginImageContext(rotatedSize);
		CGContextRef bitmap  = UIGraphicsGetCurrentContext();

		CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
		CGContextRotateCTM(bitmap, angleRadians);

		CGContextScaleCTM(bitmap, 1.0, -1.0);
		CGContextDrawImage(bitmap, CGRectMake(-img.size.width/2, -img.size.height/2, img.size.width, img.size.height), [img CGImage]);

		UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		return newImage;

}

%new - (void)displayTransitionBanner {

	NSString * types[14] = {@"moveIn", @"push", @"reveal", @"pageCurl", @"pageUnCurl", @"cube", @"alignedCube", @"flip", @"alignedFlip", @"oglFlip", @"cameraIris", @"rippleEffect", @"rotate", @"suckEffect"};
	NSString * subtypes[4] = {kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom };

    [UIView setAnimationsEnabled:YES];
    [CATransaction flush];

	CATransition * transition = [CATransition animation];
	transition.delegate = self;
	transition.duration = 1;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	transition.type = types[incomingBannerStyle -1];

	if( incomingDirection != -1)
		transition.subtype = subtypes[incomingDirection];

	[transitionBanner.layer addAnimation:transition forKey:nil];
	[transitionBanner addSubview:toView];
}

%new - (void)hideTransitionBanner {

	NSString * types[14] = {@"moveIn", @"push", @"reveal", @"pageCurl", @"pageUnCurl", @"cube", @"alignedCube", @"flip", @"alignedFlip", @"oglFlip", @"cameraIris", @"rippleEffect", @"rotate", @"suckEffect"};
	NSString * subtypes[4] = {kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom };

    [UIView setAnimationsEnabled:YES];
    [CATransaction flush];

	CATransition * transition = [CATransition animation];
	transition.delegate = self;
	transition.duration = 1;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	transition.type = types[outgoingBannerStyle -1];

	if( outgoingDirection != -1)
		transition.subtype = subtypes[outgoingDirection];

	[transitionBanner.layer addAnimation:transition forKey:nil];
}

%new - (void)animationDidStop:(CAAnimation*)theAnimation finished:(BOOL)finished {

	if(finished)
	{
		SBBannerContainerViewController * bcvc = [self presentedViewController];
		SBBannerContextView * contextView = [bcvc bannerContextView];

		// If we set rasterize to no, there will be a flickr effect. Without rasterization
		//the _UIBackdrop view is rendered incorrectly during the transition. Any ideas?

		/*if([contextView respondsToSelector:@selector(testBlur)])
			[contextView testBlur].layer.shouldRasterize = NO;
		else
			[contextView backdrop].layer.shouldRasterize = NO;*/

		// Re add the contextview to its original container
		[bcvc.view addSubview:contextView];

		//This should be seamless to the user.
		containerBanner.alpha = 0;

		fromIV = nil;
		toView = nil;
		transitionBanner = nil;
		[containerBanner removeFromSuperview];
		containerBanner = nil;
		preventRealCompletion = NO;
		[self completeTransition:YES];
	}
}

-(id)containerView {
	id orig = %orig;
	NSLog(@"conV: %@", orig);
	return orig;
}

-(id)dismissalCompletion {
	id orig = %orig;
	NSLog(@"dismissalCompletion: %@", orig);
	return orig;
}

-(BOOL)isAnimated {
	BOOL b = %orig;
	NSLog(@"isAnimated: %ld", b);
	return b;
}

-(BOOL)isInteractive {
	BOOL b = %orig;
	NSLog(@"isInteractive: %ld", b);
	return b;
}

-(BOOL)isPresenting {
	BOOL b = %orig;
	NSLog(@"isPresenting: %ld", b);
	return b;
}

-(id)presentationCompletion {
	id orig = %orig;
	NSLog(@"preCom: %@", orig);
	return orig;
}

-(NSInteger)presentationStyle {
	NSInteger orig = %orig;
	NSLog(@"presStyle: %ld", orig);
	return orig;
}

-(id)presentedViewController {
	id orig = %orig;
	NSLog(@"presVC: %@", orig);
	return orig;
}

-(id)presentingViewController {
	id orig = %orig;
	NSLog(@"presingVC: %@", orig);
	return orig;
}

-(void)setAnimated:(BOOL)b {
	%orig;
	NSLog(@"setAnimated: %ld", b);
}

-(void)setContainerView:(id)arg {
	%orig;
	NSLog(@"setContainerView: %@", arg);
}

-(void)setDismissalCompletion:(id)arg {
	%orig;
	NSLog(@"setDismissalCompletion: %@", arg);
}

-(void)setPresentationCompletion:(id)arg {
	%orig;
	NSLog(@"setPresentationCompletion: %@", arg);
}

-(void)setPresentedViewController:(id)arg {
	%orig;
	NSLog(@"setPresentedViewController: %@", arg);
}

-(void)setPresenting:(BOOL)b {
	%orig;
	NSLog(@"setPresenting: %ld", b);
}

-(void)setPresentingViewController:(id)arg {
	%orig;
	NSLog(@"setPresentingViewController: %@", arg);
}

-(CGAffineTransform)targetTransform {
	CGAffineTransform orig = %orig;
	NSLog(@"targetTransform: %@", orig);
	return orig;
}

-(BOOL)transitionWasCancelled {
	BOOL b = %orig;
	NSLog(@"transitionWasCancelled: %ld", b);
	return b;
}

-(void)updateInteractiveTransition:(CGFloat)arg {
	%orig;
	NSLog(@"updateInteractiveTransition: %f", arg);
}

-(id)viewControllerForKey:(id)arg {
	id orig = %orig;
	NSLog(@"vcfk: %@ %@", orig, arg);
	return orig;
}

-(id)viewForKey:(id)arg {
	id orig = %orig;
	NSLog(@"viewForKey: %@ %@", orig, arg);
	return orig;
}


%end

%hook SBBannerContainerViewController

-(void)animateTransition:(_SBBulletinRootViewControllerTransitionContext*)tc {

	%orig;
	NSLog(@"Original animation should have ended.");

	if(!enabled)
		return;

	if(!allowLS)
	{
		SBLockScreenManager * lsManager = (SBLockScreenManager*)[objc_getClass("SBLockScreenManager") sharedInstance];
		isUILocked = [lsManager isUILocked];

		if(isUILocked)
			return;
	}

	if(!allowNotif)
	{
		SBNotificationCenterController * cont = (SBNotificationCenterController*)[objc_getClass("SBNotificationCenterController") sharedInstance];
		isNotifVisible = [cont isVisible];

		if(isNotifVisible)
			return;
	}

	if([tc isPresenting] && disableIn)
		return;

	if(![tc isPresenting] && disableOut)
		return;

	// At this point, the banner would be visible to the user. But we want to display the banner with our
	// own animations so temporarily hide the view while we can setup the varius display effects
	SBBannerContextView * contextView = [self bannerContextView];
	contextView.alpha = 0;
}

-(CGFloat)transitionDuration:(_SBBulletinRootViewControllerTransitionContext*)tc {

	CGFloat orig = %orig;
	NSLog(@"transitionDuration arg: %@ dur: %f", tc, orig);

	if(!enabled)
		return orig;

	if(!allowLS && isUILocked)
		return orig;

	if(!allowNotif && isNotifVisible)
		return orig;

	if([tc isPresenting] && disableIn)
		return orig;

	if(![tc isPresenting] && disableOut)
		return orig; 

	return 0;
}

%end

static void loadPrefs() 
{
	NSLog(@"Loading BannerStyle prefs");
    CFPreferencesAppSynchronize(CFSTR("com.joshdoctors.bannerstyle"));

    enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.joshdoctors.bannerstyle")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.joshdoctors.bannerstyle")) boolValue];
    if (enabled) {
        NSLog(@"[BannerStyle] We are enabled");
    } else {
        NSLog(@"[BannerStyle] We are NOT enabled");
    }

    allowLS = !CFPreferencesCopyAppValue(CFSTR("allowLS"), CFSTR("com.joshdoctors.bannerstyle")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("allowLS"), CFSTR("com.joshdoctors.bannerstyle")) boolValue];
    allowNotif = !CFPreferencesCopyAppValue(CFSTR("allowNotif"), CFSTR("com.joshdoctors.bannerstyle")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("allowNotif"), CFSTR("com.joshdoctors.bannerstyle")) boolValue];
    
    incomingBannerStyle = !CFPreferencesCopyAppValue(CFSTR("incomingBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) ? 0 : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("incomingBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) intValue];
    incomingDirection = !CFPreferencesCopyAppValue(CFSTR("incomingDirection"), CFSTR("com.joshdoctors.bannerstyle")) ? 0 : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("incomingDirection"), CFSTR("com.joshdoctors.bannerstyle")) intValue];

    outgoingBannerStyle = !CFPreferencesCopyAppValue(CFSTR("outgoingBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) ? 0 : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("outgoingBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) intValue];
    outgoingDirection = !CFPreferencesCopyAppValue(CFSTR("outgoingDirection"), CFSTR("com.joshdoctors.bannerstyle")) ? 0 : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("outgoingDirection"), CFSTR("com.joshdoctors.bannerstyle")) intValue];

	materialBannerStyle = !CFPreferencesCopyAppValue(CFSTR("materialBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) ? 0 : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("materialBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) intValue];

    if (incomingBannerStyle > 10 )
    	incomingDirection = -1;

    if (outgoingBannerStyle > 10 )
    	outgoingDirection = -1;

    if(outgoingBannerStyle == 1 )
    	disableOut = YES;
    else
    	disableOut = NO;

    if(incomingBannerStyle == 22 )
    	disableIn = YES;
    else
    	disableIn = NO;
}

static void showTestBanner()
{
	[[%c(SBBulletinBannerController) sharedInstance] _showTestBanner:YES];
}

%ctor
{
	NSLog(@"Loading BannerStyle");
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)loadPrefs,
                                CFSTR("com.joshdoctors.bannerstyle/settingschanged"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)showTestBanner,
                                CFSTR("com.joshdoctors.bannerstyle/showtestbanner"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);
	loadPrefs();
}