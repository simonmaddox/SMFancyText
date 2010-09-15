//
//  SMFancyText.h
//  SMFancyText
//
//  Created by Simon Maddox on 12/08/2010.
//  Copyright 2010 Sensible Duck Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libxml/htmlparser.h>

@class SMFancyTextElement;


@protocol SMFancyTextDelegate <NSObject>

- (void) linkPressed:(UIButton *)link;

@end

@interface SMFancyText : UIView {
	NSString *text;
	id <SMFancyTextDelegate> delegate;
	
	@private
	UIColor *_textColor;
	htmlParserCtxtPtr context;
	NSMutableArray *elements;
	SMFancyTextElement *currentElement;
	CGPoint currentPosition;
}

@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, assign) id <SMFancyTextDelegate> delegate;

@property (nonatomic, retain) SMFancyTextElement *currentElement;
@property (nonatomic, retain) NSMutableArray *elements;

- (void) setText: (NSString *) newText;

@end