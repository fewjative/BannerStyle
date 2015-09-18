#import <Preferences/Preferences.h>
#import <Social/SLComposeViewController.h>
#import <Social/SLServiceTypes.h>
#import <UIKit/UIKit.h>

static NSInteger bannerStyle = 0;

@interface BannerStyleSettingsListController: PSEditableListController {
}
@end

@interface ViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@end

@implementation BannerStyleSettingsListController
- (id)specifiers {
	if(_specifiers == nil) {

		bannerStyle = (!CFPreferencesCopyAppValue(CFSTR("bannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) ? 0 : [(id)CFPreferencesCopyAppValue(CFSTR("bannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) intValue]);

        if(bannerStyle > 10)
            _specifiers = [[self loadSpecifiersFromPlistName:@"BannerStyleSettingsWithoutDirection" target:self] retain];
        else
            _specifiers = [[self loadSpecifiersFromPlistName:@"BannerStyleSettingsWithDirection" target:self] retain];
	}
	return _specifiers;
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

-(void)viewDidLoad{

	[super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self reload];
	[self reloadSpecifiers];
}

-(void)twitter {

	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/Fewjative"]];

}

-(void)showTestBanner{
		CFPreferencesAppSynchronize(CFSTR("com.joshdoctors.bannerstyle"));
		CFNotificationCenterPostNotification(
		CFNotificationCenterGetDarwinNotifyCenter(),
		CFSTR("com.joshdoctors.bannerstyle/showtestbanner"),
		NULL,
		NULL,
		YES
		);
}

-(id)_editButtonBarItem{
	return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeTweet:)];
}

-(void)composeTweet:(id)sender
{
	SLComposeViewController * composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
	[composeController setInitialText:@"I downloaded #BannerStyle by @Fewjative and my banners look sweet!"];
	[self presentViewController:composeController animated:YES completion:nil];
}

-(void)save
{
    [self.view endEditing:YES];
}

@end