#import "SMFancyTextElement.h"

@implementation SMFancyTextElement

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
