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
@class SMFancyText;

@protocol SMFancyTextDelegate <NSObject>

- (void)fancyText:(SMFancyText *)fancyText linkPressed:(UIButton *)link;

@end

@interface SMFancyText : UIView {
@private
	htmlParserCtxtPtr _context;
	CGPoint _currentPosition;
}

@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, assign) id <SMFancyTextDelegate> delegate;
@property (nonatomic, retain) SMFancyTextElement *currentElement;
@property (nonatomic, retain) NSMutableArray *elements;

- (void)setText:(NSString *)newText;

@end
