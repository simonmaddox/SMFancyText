//
//  SMFancyTextViewController.m
//  SMFancyText
//
//  Created by Simon Maddox on 15/09/2010.
//  Copyright 2010 Sensible Duck Ltd. All rights reserved.
//

#import "SMFancyTextViewController.h"

@implementation SMFancyTextViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	
	SMFancyText *fancyText = [[SMFancyText alloc] initWithFrame:CGRectMake(20, 20, 280, 420)];
	[fancyText setText:@"<p>This is a long block of text that has no formatting at all. And <b>now we've got bold in the middle of a sentence</b> and even <i>italics (if you're not on an iPhone 4)</i></p><p><a href=\"http://google.com\">This is a link to Google</a></p><p><a href=\"http://apple.com\"><img src=\"safari.gif\" /></a></p><ul><li>And</li><li>this</li><li>is</li><li>a list</li></ul><blockquote>OMG shocking quote here. This is really a blockquote</blockquote>"];
	[fancyText setBackgroundColor:[UIColor whiteColor]];
	[fancyText setDelegate:self];
	[self.view addSubview:fancyText];
	[fancyText release];
}

- (void)fancyText:(SMFancyText *)fancyText linkPressed:(UIButton *)link {
	NSLog(@"Opening: %@", [[link titleLabel] text]);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
