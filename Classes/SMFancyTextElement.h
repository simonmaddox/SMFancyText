#import <Foundation/Foundation.h>

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

@interface SMFancyTextElement : NSObject {
@private
	UIColor *_textColor;
}

@property (nonatomic, retain) NSString *text;
@property SMFancyTextElementStyle style;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *imageName;

@end
