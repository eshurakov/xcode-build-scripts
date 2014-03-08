//
//  ViewController.m
//  XcodeBuildScripts
//
//  Created by Evgeny Shurakov on 08.03.14.
//  Copyright (c) 2014 Evgeny Shurakov. All rights reserved.
//

#import "ViewController.h"
#import "Version.h"

@interface ViewController ()
@property(nonatomic, strong) IBOutlet UILabel *versionLabel;
@property(nonatomic, strong) IBOutlet UILabel *buildHashLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSBundle *bundle = [NSBundle mainBundle];
	NSString *v1 = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *v2 = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *v3 = @"";
	
#ifdef XC_BUILD_HASH
	v3 = XC_BUILD_HASH;
#endif
	
	self.versionLabel.text = [NSString stringWithFormat:@"%@.%@", v1, v2];
    self.buildHashLabel.text = v3;
}

@end
