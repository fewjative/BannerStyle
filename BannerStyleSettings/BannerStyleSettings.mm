#import <Preferences/Preferences.h>
#import <Social/SLComposeViewController.h>
#import <Social/SLServiceTypes.h>
#import <UIKit/UIKit.h>

static NSInteger incomingBannerStyle = 0;
static NSInteger outgoingBannerStyle = 0;

@interface BannerStyleSettingsListController: PSEditableListController {
}
@end

@interface ViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@end

@implementation BannerStyleSettingsListController
- (id)specifiers {
	if(_specifiers == nil) {

		incomingBannerStyle = (!CFPreferencesCopyAppValue(CFSTR("incomingBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) ? 0 : [(id)CFPreferencesCopyAppValue(CFSTR("incomingBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) intValue]);
		outgoingBannerStyle = (!CFPreferencesCopyAppValue(CFSTR("outgoingBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) ? 0 : [(id)CFPreferencesCopyAppValue(CFSTR("outgoingBannerStyle"), CFSTR("com.joshdoctors.bannerstyle")) intValue]);

		if(incomingBannerStyle > 10 && outgoingBannerStyle == 1)
		{
			if(incomingBannerStyle == 15)
				_specifiers = [[self loadSpecifiersFromPlistName:@"BannerStyleSettingsMaterialNoDirection" target:self] retain];
			else
				_specifiers = [[self loadSpecifiersFromPlistName:@"BannerStyleSettingsNoDirection" target:self] retain];
		}
		else if(incomingBannerStyle > 10)
		{
			if(incomingBannerStyle == 15)
				_specifiers = [[self loadSpecifiersFromPlistName:@"BannerStyleSettingsMaterialOutgoingDirection" target:self] retain];
			else
				_specifiers = [[self loadSpecifiersFromPlistName:@"BannerStyleSettingsOutgoingDirection" target:self] retain];
		}
		else if(outgoingBannerStyle == 1 )
		{
			_specifiers = [[self loadSpecifiersFromPlistName:@"BannerStyleSettingsIncomingDirection" target:self] retain];
		}
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