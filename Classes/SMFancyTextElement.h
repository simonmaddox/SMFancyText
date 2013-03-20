#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SMFancyTextElementStyle) {
	SMFancyTextElementStyleNormal,
	SMFancyTextElementStyleBold,
	SMFancyTextElementStyleItalic,
	SMFancyTextElementStyleNewLine,
	SMFancyTextElementStyleParagraphBreak,
	SMFancyTextElementStyleListItem,
	SMFancyTextElementStyleBlockQuote,
	SMFancyTextElementStyleLink,
	SMFancyTextElementStyleImage,
	SMFancyTextElementStyleImageLink
};

@interface SMFancyTextElement : NSObject

+ (instancetype)textElement;
+ (instancetype)textElementWithStyle:(SMFancyTextElementStyle)style;

@property (nonatomic, retain) NSString *text;
@property SMFancyTextElementStyle style;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *imageName;

@end
