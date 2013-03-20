#import "SMFancyTextElement.h"

@implementation SMFancyTextElement

+ (instancetype)textElement {
	return [self textElementWithStyle:SMFancyTextElementStyleNormal];
}

+ (instancetype)textElementWithStyle:(SMFancyTextElementStyle)style {
	SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];

	element.style = style;

	return element;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"SMFancyTextElement ::  %@ - %d", _text, _style];
}

- (void)dealloc {

	[_text release];
	[_link release];
	[_imageName release];

	_text = nil;
	_link = nil;
	_imageName = nil;

	[super dealloc];
}

@end
