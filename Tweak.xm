#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <substrate.h>
#include "InspCWrapper.m"

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

@interface _SBBulletinRootViewControllerTransitionContext
-(UIView*)containerView;
@end

@interface _UIBackdropView : UIView
@end

@interface SBBannerContainerViewController : UIViewController
-(CGFloat)transitionDuration:(_SBBulletinRootViewControllerTransitionContext*)tc;
-(UIView*)bannerContextView;
@end

@implementation CALayer (NPAnchorPosition)

- (void)setAnchorPointWhileMaintainingPosition:(CGPoint)anchorPoint {
    [self setAnchorPoint:anchorPoint];
    [self setPosition:CGPointMake(self.position.x + self.bounds.size.width * (self.anchorPoint.x - 0.5), self.position.y + self.bounds.size.height * (self.anchorPoint.y - 0.5))];
}

@end

static UIView * animatedBanner = nil;
static UIView * transitionBanner = nil;
static UIView * containerBanner = nil;
static UIImageView * animatedBannerIV = nil;
static UIImageView * fromIV = nil;
static UIImageView * toIV = nil;
static UIImageView * background = nil;
static UIView * toView = nil;
static SBBannerContainerView * container = nil;
static SBBannerContextView * bannerContext = nil;
static CGRect defaultIconFrame;
static _SBBulletinRootViewControllerTransitionContext * transitionContext = nil;
static BOOL displayingBanner = NO;
static BOOL inCompletion = NO;
static _UIBackdropView * backDrop = nil;
static BOOL preventRealCompletion = YES;

%hook _SBBulletinRootViewControllerTransitionContext

-(void)cancelInteractiveTransition {
	%orig;
	NSLog(@"CancelIT");
}

-(void)completeTransition:(BOOL)b {

	NSLog(@"compTr: %ld", b);
	if(![self isPresenting])
	{
		%orig;
	}
	else if(preventRealCompletion)
	{
		int style = 4;
		if( style == 0 || style == 1 || style == 2 )
		{
			[self displayStaticBanner:style];
		}
		else if(style == 3)
		{
			[self setupTransitionBanner];
			[self displayTransitionBanner];
		}
		else if(style == 4)
		{
			[self setupAnimatedBanner];
			[self displayAnimatedBanner];
		}
	}
	else
	{
		%orig;
		preventRealCompletion = YES;
	}
}

%new - (void)displayStaticBanner:(NSInteger)position
{
	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];
	CGRect baseRect = contextView.frame;

	switch (position)
	{
		case 0:
			contextView.frame = CGRectMake(baseRect.size.width, baseRect.origin.y, baseRect.size.width, baseRect.size.height);
			contextView.alpha = 1;

			[UIView animateWithDuration:0.40f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
				contextView.frame = baseRect;
			}
			completion:^(BOOL finished) {
				preventRealCompletion = NO;
				[self completeTransition:YES];
			}];
		break;

		case 1:
			contextView.frame = CGRectMake(-baseRect.size.width, baseRect.origin.y, baseRect.size.width, baseRect.size.height);
			contextView.alpha = 1;

			[UIView animateWithDuration:0.40f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
				contextView.frame = baseRect;
			}
			completion:^(BOOL finished) {
				preventRealCompletion = NO;
				[self completeTransition:YES];
			}];
		break;

		case 2:
			contextView.frame = CGRectMake(baseRect.origin.x, [UIScreen mainScreen].bounds.size.height, baseRect.size.width, baseRect.size.height);
			contextView.alpha = 1;

			[UIView animateWithDuration:0.40f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
				contextView.frame = baseRect;
			}
			completion:^(BOOL finished) {
				preventRealCompletion = NO;
				[self completeTransition:YES];
			}];
		break;
	}
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

	int style = 0;

	if(style==0) //circle
	{
		layerMask.path = [UIBezierPath bezierPathWithRoundedRect:maskRect cornerRadius:animatedBanner.bounds.size.height].CGPath;
	}
	else if (style == 1) //square
	{
		layerMask.path = [UIBezierPath bezierPathWithRect:maskRect].CGPath;
	} 
	else if (style == 2) //diamond
	{
		CGPathMoveToPoint(path, nil, maskRect.origin.x + maskRect.size.width/2, maskRect.origin.y);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x + maskRect.size.width, maskRect.size.height/2);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x + maskRect.size.width/2, maskRect.size.height);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x, maskRect.size.height/2);
		CGPathCloseSubpath(path);
		layerMask.path = path;
	}
	else if (style == 3) //triangle
	{
		CGPathMoveToPoint(path, nil, maskRect.origin.x + maskRect.size.width/2, maskRect.origin.y);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x + maskRect.size.width, maskRect.size.height);
		CGPathAddLineToPoint(path, nil, maskRect.origin.x, maskRect.size.height);
		CGPathCloseSubpath(path);
		layerMask.path = path;

		//need to change imageview to center of triangle
	}
	else if (style == 4) //star
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


	UIImage * curentScreen =  _UICreateScreenUIImage();

	// fromIV is just a snapshot of the current banner area(no banner is currently visible)
	fromIV = [[UIImageView alloc] initWithFrame:baseRect];
	fromIV.image = curentScreen;
	fromIV.contentMode = UIViewContentModeTopLeft;
	fromIV.clipsToBounds = YES;

	//background.image = curentScreen;
	//background.contentMode = UIViewContentModeTopLeft;
	//background.clipsToBounds = YES;
	//[background release];
	
	[transitionBanner addSubview:fromIV];
	[containerBanner addSubview:transitionBanner];
	[bcvc.view insertSubview:containerBanner atIndex:0];
}

%new - (void)displayTransitionBanner {

    [UIView setAnimationsEnabled:YES];
    [CATransaction flush];

	CATransition * transition = [CATransition animation];
	transition.delegate = self;
	transition.duration = 1;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	transition.type = @"cube";
	transition.subtype = kCATransitionFromBottom;
	[transitionBanner.layer addAnimation:transition forKey:nil];
	[transitionBanner addSubview:toView];
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

		[fromIV release];
		fromIV = nil;
		[toView release];
		toView = nil;
		[transitionBanner release];
		transitionBanner = nil;
		[containerBanner removeFromSuperview];
		[containerBanner release];
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

-(void)dealloc {
	%orig;
	NSLog(@"deall");
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

	// Only perform actions if we are going to be presenting the banner to the user
	if(![tc isPresenting])
		return;

	// At this point, the banner would be visible to the user. But we want to display the banner with our
	// own animations so temporarily hide the view while we can setup the varius display effects
	SBBannerContextView * contextView = [self bannerContextView];
	contextView.alpha = 0;
}

-(CGFloat)transitionDuration:(_SBBulletinRootViewControllerTransitionContext*)tc {

	CGFloat orig = %orig;
	NSLog(@"transitionDuration arg: %@ dur: %f", tc, orig);

	if([tc isPresenting])
		return 0;
	else
		return orig;
}

%end
