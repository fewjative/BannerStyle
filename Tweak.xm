#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <substrate.h>
#include "InspCWrapper.m"

extern "C" UIImage * _UICreateScreenUIImage();

@interface SBBannerContainerView : UIView
@end

@interface SBBannerContextView : UIView
-(CGRect)frame;
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

static UIView * newBanner = nil;
static UIView * flipBanner = nil;
static UIImageView * newBannerIV = nil;
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
		int style = 2;
		if( style == 0 || style == 1 || style == 2 )
		{
			[self displayStaticBanner:style];
		}
		else if(style == 3)
		{
			[self setupFlipBanner];
			[self displayFlipBanner];
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

%new - (void)setupFlipBanner {

	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];
	CGRect baseRect = contextView.frame;

	UIGraphicsBeginImageContextWithOptions(baseRect.size, NO, 0.0f);
	contextView.alpha = 1;
	//[contextView.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage * toImage = UIGraphicsGetImageFromCurrentImageContext();
	//contextView.alpha = 0;
	//[contextView drawViewHierarchyInRect:baseRect afterScreenUpdates:YES];
	[[[UIApplication sharedApplication] keyWindow].layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage * fromImage = UIGraphicsGetImageFromCurrentImageContext();
	NSLog(@"Image: %@", fromImage);
	UIGraphicsEndImageContext();

	if(!flipBanner)
		flipBanner = [[UIView alloc] initWithFrame:baseRect];

	UIImageView * toIV = [[UIImageView alloc] initWithFrame:baseRect];
	toIV.image = toImage;
	toIV.contentMode = UIViewContentModeTopLeft;
	toIV.clipsToBounds = YES;
	contextView.alpha = 0;

	UIImageView * fromIV = [[UIImageView alloc] initWithFrame:baseRect];
	fromIV.image = _UICreateScreenUIImage();
	fromIV.contentMode = UIViewContentModeTopLeft;
	fromIV.clipsToBounds = YES;

	//[flipBanner addSubview:fromIV];
	[flipBanner addSubview:toIV];
	[fromIV release];
	[toIV release];

	[bcvc.view insertSubview:flipBanner atIndex:0];
}

%new - (void)displayFlipBanner {
	return;
	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];

	[UIView transitionFromView:[[flipBanner subviews] objectAtIndex:0]
						toView:[[flipBanner subviews] objectAtIndex:1]
						duration:0.5f
						options:UIViewAnimationOptionTransitionFlipFromBottom
						completion:^(BOOL finished)
						{
							/*flipBanner.alpha = 0;
							contextView.alpha = 1;*/
							NSLog(@"Flip completed");
							[flipBanner removeFromSuperview];
							preventRealCompletion = NO;
							[self completeTransition:YES];
						}];
}



%new - (void)setupAnimatedBanner {

	SBBannerContainerViewController * bcvc = [self presentedViewController];
	SBBannerContextView * contextView = [bcvc bannerContextView];
	NSLog(@"Context: %@", contextView);
	CGRect baseRect = CGRectMake(0,0,contextView.bounds.size.width,contextView.bounds.size.height);

	if(!newBanner)
		newBanner = [[UIView alloc] init];

	newBanner.frame = baseRect;

	newBanner.alpha = 0.3;

	if(!newBannerIV)
		newBannerIV = [[UIImageView alloc] init];

	[newBanner addSubview:newBannerIV];
	[bcvc.view insertSubview:newBanner atIndex:0];

	SBDefaultBannerView  * def = [contextView  _vibrantContentView];
	UIImageView  * iconImageView = MSHookIvar<UIImageView*>(def,"_iconImageView");
	CGRect oldFrame = [iconImageView frame];

	if(!CGRectEqualToRect(contextView.frame,def.frame))
	{
		CGRect currentFrame = [def _contentFrame];
		CGFloat half = baseRect.size.width/2;
		CGFloat start = half - currentFrame.size.width/2;
		defaultIconFrame = CGRectMake(start, oldFrame.origin.y, oldFrame.size.width, oldFrame.size.height);
	}
	else
		defaultIconFrame = oldFrame;

	CGRect centerRect = CGRectMake(baseRect.size.width/2 - oldFrame.size.width/2, baseRect.size.height/2 - oldFrame.size.height/2, oldFrame.size.width, oldFrame.size.height);
	NSLog(@"centerRect: %@", NSStringFromCGRect(centerRect));
	newBannerIV.frame = centerRect;
	newBannerIV.image = [iconImageView image];

	if([contextView respondsToSelector:@selector(testBlur)])
		[self setBackdrop:[contextView testBlur]];
	else
		[self setBackdrop:[contextView backdrop]];
}

%new -(void)displayAnimatedBanner {

	NSLog(@"Displaying banner");

	CGRect maskRect = CGRectMake(newBanner.bounds.size.width/2 - newBanner.bounds.size.height/2, 0, newBanner.bounds.size.height, newBanner.bounds.size.height);
	NSLog(@"Mask Rect: %@", NSStringFromCGRect(maskRect));


	CAShapeLayer * layerMask = [CAShapeLayer layer];
	layerMask.fillColor = [UIColor blackColor].CGColor;
	CGMutablePathRef path = CGPathCreateMutable();

	int style = 2;

	if(style==0) //circle
	{
		layerMask.path = [UIBezierPath bezierPathWithRoundedRect:maskRect cornerRadius:newBanner.bounds.size.height].CGPath;
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
	layerMask.frame = CGRectMake(0,0,68,68);
	layerMask.bounds = CGRectMake(0,0,68,68);
	newBanner.layer.mask = layerMask;
	newBanner.transform = CGAffineTransformMakeScale(0.1,0.1);

	[UIView setAnimationsEnabled:YES];
	[UIView animateWithDuration:0.30 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.0f options:0 animations:^{
		newBanner.transform = CGAffineTransformMakeScale(0.8,0.8);
		newBanner.alpha = 1;
	} completion:^(BOOL completed){

		if(completed)
		{
			NSLog(@"Completed animation 1");
			newBanner.transform = CGAffineTransformIdentity;
			newBanner.layer.transform = CATransform3DIdentity;
			
			CGPathRelease(path);

			CGFloat pct = 12;
			[CATransaction begin];
			layerMask.transform = CATransform3DIdentity;
			layerMask.anchorPoint = CGPointMake(0.5,0.5);
			layerMask.frame = newBanner.frame;
			NSLog(@"center: %@", NSStringFromCGPoint(newBanner.layer.position));

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

			[newBanner.layer.mask addAnimation:anim forKey:@"scale"];
			[CATransaction commit];

			/*return;
			preventRealCompletion = NO;
			[self completeTransition:YES];*/

			[UIView animateWithDuration:0.30f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
				newBannerIV.frame = defaultIconFrame;
			}
			completion:^(BOOL finished) {
				NSLog(@"center: %@", NSStringFromCGPoint(layerMask.position));
				newBanner.alpha = 0;
				SBBannerContainerViewController * bcvc = [self presentedViewController];
				[bcvc bannerContextView].alpha = 1;
				[newBanner removeFromSuperview];
				preventRealCompletion = NO;
				[self completeTransition:YES];
			}];
		}
	}];
}

%new - (void)setBackdrop:(_UIBackdropView*)backdrop {
	for (UIView * view in newBanner.subviews) {
    	if([view isKindOfClass:[%c(_UIBackdropView) class]])
    	{
    		[view removeFromSuperview];
    	}
    }

    NSLog(@"Current settings: %@", [backdrop inputSettings]);
    NSLog(@"Current settings out: %@", [backdrop outputSettings]);
    _UIBackdropView * blurView = [[_UIBackdropView alloc] initWithSettings:[backdrop inputSettings]];
	[newBanner insertSubview:blurView atIndex:0];
	NSLog(@"BlurView: %@", blurView);
	NSLog(@"Tint: %@", [blurView colorMatrixColorTint]);
	[blurView release];
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

-(CGRect)initialFrameForViewController:(id)arg {
	CGRect orig = %orig;
	NSLog(@"initFFVC: %@ %@", NSStringFromCGRect(orig), arg);
	return CGRectMake(0,0,0,0);
}

-(CGRect)finalFrameForViewController:(id)arg {
	CGRect orig = %orig;
	NSLog(@"initFFVC: %@ %@", NSStringFromCGRect(orig), arg);
	return CGRectMake(0,0,0,0);
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
	NSLog(@"preCOm: %@", orig);

	displayingBanner = NO;
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

//ASSIGN TAGS, POP 'isDisplaying' from the stack?

%hook SBDefaultBannerView

-(void)layoutSubviews {
	%orig;

	NSLog(@"SBDBV ls, %@", self);
	NSLog(@"backdrop: %@",[[[self superview] superview] backdrop]);
	NSLog(@"bd sett: %@", [[[[self superview] superview] backdrop] inputSettings]);
}

%end

%hook SBBannerContainerViewController

-(void)animateTransition:(_SBBulletinRootViewControllerTransitionContext*)tc {

	NSLog(@"ANIMATE TRANSITION START");
	%orig;
	NSLog(@"ANIMATE TRANSITION END, now to bring home the bacon.");

	if(![tc isPresenting])
		return;

	SBBannerContextView * contextView = [self bannerContextView];
	contextView.alpha = 0;
}

-(CGFloat)transitionDuration:(_SBBulletinRootViewControllerTransitionContext*)tc {
	NSLog(@"transitionDuration: %@", tc);
	CGFloat orig = %orig;
	NSLog(@"float: %f", orig);
	NSLog(@"isPresenting: %d", [tc isPresenting]);

	if([tc isPresenting])
	{
		return 0;
	}
	else
	{
		return orig;
	}
}

%end

%hook _UIBackdropView

-(void)setColorMatrixColorTint:(id)arg {
	NSLog(@"setting color matrix: %@", arg);
	%orig;
}

-(id)colorMatrixColorTint {
	UIColor * orig = %orig;
	NSLog(@"Color m: %@", orig);
	return orig;
}

%end


%hook SBBannerContextView
-(void)_layoutContentView {
	NSLog(@"_layoutContentViewt");
	%orig;
}

-(void)setBannerContext:(id)context withReplaceReason:(int)reason {
	NSLog(@"colorized dathbanners");
	%orig;
	NSLog(@"Current settings: %@", [[self backdrop] inputSettings]);

}

/*-(void)layoutSubviews {
	%orig;

	CGRect base = CGRectMake(0,0,self.frame.size.width, self.frame.size.height);

	self.frame = CGRectMake(self.frame.size.width,0, self.frame.size.width, self.frame.size.height);
	[UIView animateWithDuration:0.5 animations:^{
		self.frame = base;
	}];
}*/

%end

%hook SBBulletinBannerController

-(id)newBannerViewForContext:(id)arg{
	NSLog(@"newBannerViewForContext");
	return %orig;
}

%end

%hook SBBannerController


-(void)_performRevealTransitionWithContext:(id)arg1 animated:(BOOL)arg2 completion:(/*^block*/id)arg3  { %log;

/*[UIView animateWithDuration:0.5f delay:0.0 options:nil animations:^{
			}
			completion:arg3];
			*/
			%orig;
			NSLog(@"Finished with the buck");
			//[self.view.layer removeAllAnimations];
			 }



%end




%ctor {

  // watchObject(...);
  ////setMaximumRelativeLoggingDepth(1);

  //watchSelector(@selector(animateTransition:));
  ////watchClass(%c(SBBannerContainerViewController));

  // SpringBoard application.
  //watchSelector(@selector(applicationDidFinishLaunching:));
}
