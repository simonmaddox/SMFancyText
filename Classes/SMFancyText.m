//
//  SMFancyText.m
//  SMFancyText
//
//  Created by Simon Maddox on 12/08/2010.
//  Copyright 2010 Sensible Duck Ltd. All rights reserved.
//

#import "SMFancyText.h"

#define HTMLBullet @"•"

#pragma mark -
#pragma mark LibXML Headers


void startElementSAX (void * ctx, const xmlChar * name, const xmlChar ** atts);
void endElementSAX (void * ctx, const xmlChar * name);
void charactersFound (void * ctx, const xmlChar * ch, int len);
void endDocumentSAX (void * ctx);
void errorEncountered (void *ctx, const char *msg, ...);

static xmlSAXHandler simpleSAXHandlerStruct;


#pragma mark -
#pragma mark SMFancyTextElement

typedef enum 
{
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
} SMFancyTextElementStyle;

@interface SMFancyTextElement : NSObject
{
	NSString *text;
	SMFancyTextElementStyle style;
	UIColor *textColor;
	NSString *link;
	NSString *imageName;
}

@property (nonatomic, retain) NSString *text;
@property SMFancyTextElementStyle style;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *imageName;

@end

#pragma mark -
#pragma mark SMFancyText

@interface SMFancyText ()

- (void) saveCurrentElement;
- (void) drawString:(NSString *) string withFont:(UIFont *) font atPoint:(CGPoint) point inRect:(CGRect) rect recursive:(BOOL) recursive style:(SMFancyTextElementStyle) style withLink:(NSString *) link image:(NSString *) image;
- (NSString *) removeLeadingWhiteSpaceFromString:(NSString *) string;

@end


@implementation SMFancyText

@synthesize currentElement, elements, textColor = _textColor, delegate;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.elements = [NSMutableArray array];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
	
	if (self.textColor == nil){
		self.textColor = [UIColor blackColor];
	}
	
	CGContextSetFillColorWithColor(graphicsContext, [self.textColor CGColor]);
	
    for (NSInteger i = 0; i < [self.elements count]; i++){		
		UIFont *font = nil;
		
		switch ([[self.elements objectAtIndex:i] style]) {				
			case SMFancyTextElementStyleBold:
			case SMFancyTextElementStyleBlockQuote:
				font = [UIFont boldSystemFontOfSize:14.0];
				break;
			case SMFancyTextElementStyleItalic:
				font = [UIFont italicSystemFontOfSize:14.0];
				break;
			default:
				font = [UIFont systemFontOfSize:14.0];
				break;
		}
		
		if ([[self.elements objectAtIndex:i] style] == SMFancyTextElementStyleBlockQuote){
			CGContextFillRect(graphicsContext, CGRectMake(0, currentPosition.y - 5, rect.size.width, 2));
		}

		if ([[self.elements objectAtIndex:i] style] == SMFancyTextElementStyleParagraphBreak){
			currentPosition.x = 0;
			currentPosition.y = currentPosition.y + (18 * 2);
		} else if ([[self.elements objectAtIndex:i] style] == SMFancyTextElementStyleNewLine){
			currentPosition.x = 0;
			currentPosition.y = currentPosition.y + 18;
		} else {
			[self drawString:[[self.elements objectAtIndex:i] text] withFont:font atPoint:currentPosition inRect:rect recursive:YES style:[[self.elements objectAtIndex:i] style] withLink:[[self.elements objectAtIndex:i] link] image:[[self.elements objectAtIndex:i] imageName]];
		}
		
		if ([[self.elements objectAtIndex:i] style] == SMFancyTextElementStyleBlockQuote){
			CGContextFillRect(graphicsContext, CGRectMake(0, currentPosition.y + 20, rect.size.width, 2));
		}
	}
}

- (void) drawString:(NSString *) string withFont:(UIFont *) font atPoint:(CGPoint) point inRect:(CGRect) rect recursive:(BOOL) recursive style:(SMFancyTextElementStyle) style withLink:(NSString *) link image:(NSString *) image
{
	if (point.x == 0){
		string = [self removeLeadingWhiteSpaceFromString:string];
	}
	
	CGSize size = [string sizeWithFont:font];
	
	if (point.x + size.width > rect.size.width){
		if (recursive){
			NSArray *words = [string componentsSeparatedByString:@" "];
			for (NSInteger i = 0; i < [words count]; i++){
				if (i < [words count] - 1){
					[self drawString:[NSString stringWithFormat:@"%@ ", [words objectAtIndex:i]] withFont:font atPoint:currentPosition inRect:rect recursive:NO style:style withLink:link image:image];
				} else {
					[self drawString:[NSString stringWithFormat:@"%@", [words objectAtIndex:i]] withFont:font atPoint:currentPosition inRect:rect recursive:NO style:style withLink:link image:image];
				}
			}
			return;
		} else {
			[self drawString:string withFont:font atPoint:CGPointMake(0, currentPosition.y + size.height) inRect:rect recursive:NO style:style withLink:link image:image];
			return;
		}
	}
	
	if (size.width <= rect.size.width && currentPosition.x + size.width > rect.size.width){
		currentPosition.y += size.height;
		currentPosition.x = 0;
	}
	
	CGRect theRect = CGRectMake(currentPosition.x, currentPosition.y, size.width, size.height);
		
	if (link != nil || image != nil){
		CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
		
		if (style == SMFancyTextElementStyleLink){
			if ([delegate respondsToSelector:@selector(linkPressed:)]){
				UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
				[button setFrame:theRect];
				[button setTitle:link forState:UIControlStateNormal];
				[button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
				[button addTarget:self action:@selector(linkTouchUp:) forControlEvents:UIControlEventTouchUpInside];
				[button addTarget:self action:@selector(linkPressed:) forControlEvents:UIControlEventTouchDown];
				[self addSubview:button];
				
				CGContextSetFillColorWithColor(graphicsContext, [[UIColor colorWithRed:65.0/255.0 green:123.0/255.0 blue:192.0/255.0 alpha:1] CGColor]);
				CGContextFillRect(graphicsContext, CGRectMake(currentPosition.x, currentPosition.y + (theRect.size.height - 2), theRect.size.width, 1));
				[string drawInRect:theRect withFont:font];
				CGContextSetFillColorWithColor(graphicsContext, [self.textColor CGColor]);
			}
		} else if (style == SMFancyTextElementStyleImage){
			UIImage *theImage = [UIImage imageNamed:image];
			[theImage drawInRect:CGRectMake((self.frame.size.width / 2) - (theImage.size.width / 2), currentPosition.y, theImage.size.width, theImage.size.height)];
			currentPosition.y += theImage.size.height;
		} else if (style == SMFancyTextElementStyleImageLink){
			UIImage *theImage = [UIImage imageNamed:image];
			
			CGRect imageFrame = CGRectMake((self.frame.size.width / 2) - (theImage.size.width / 2), currentPosition.y, theImage.size.width, theImage.size.height);
			[theImage drawInRect:imageFrame];
			
			UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
			[button setFrame:imageFrame];
			[button setTitle:link forState:UIControlStateNormal];
			[button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
			[button addTarget:delegate action:@selector(linkPressed:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
			
			currentPosition.y += theImage.size.height;
		}
	} else {
		[string drawInRect:theRect withFont:font];
	}
		
	currentPosition = CGPointMake(currentPosition.x + size.width, currentPosition.y);
}

- (void) linkPressed:(UIButton *) button
{
	[button setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2]];
}

- (void) linkTouchUp: (UIButton *) button
{
	[button setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0]];
	[delegate linkPressed:button];
}

- (void) setText:(NSString *)newText
{
	NSData *data = [[NSString stringWithFormat:@"<SMFancyText>%@</SMFancyText>",[newText stringByReplacingOccurrencesOfString:@"\n" withString:@""]] dataUsingEncoding:NSUTF8StringEncoding];

	context = htmlCreatePushParserCtxt(&simpleSAXHandlerStruct, self, NULL, 0, NULL, 0);
	htmlParseChunk(context, (const char *)[data bytes], [data length], 0);
}

- (NSString *) removeLeadingWhiteSpaceFromString:(NSString *) string
{
	if (string == nil){
		return nil;
	}
	
	NSMutableString *mutableString = [NSMutableString stringWithString:string];
	
	for (NSInteger i = 0; i < [string length]; i++){
		if ([[mutableString substringToIndex:1] isEqualToString:@" "]){
			[mutableString deleteCharactersInRange:NSMakeRange(0, 1)];
		}
	}
	
	return [NSString stringWithString:mutableString];
}

- (void)dealloc {
	self.text = nil;
	self.currentElement = nil;
    [super dealloc];
}

- (void) saveCurrentElement
{
	if (self.currentElement == nil){
		return;
	}
	[self.elements addObject:self.currentElement];
	self.currentElement = nil;
}


#pragma mark -
#pragma mark LibXML

void startElement (void * ctx, const xmlChar * name, const xmlChar ** atts)
{	
	SMFancyText *textView = (SMFancyText *) ctx;
	
	if (textView.currentElement.style == SMFancyTextElementStyleLink && !strcmp((char *)name, "img")){
		textView.currentElement.style = SMFancyTextElementStyleImageLink;
		
		for (NSInteger i = 0; i < sizeof(atts); i++){
			if (!strcmp((char *)atts[i], "src")){
				textView.currentElement.imageName = [NSString stringWithCString:(const char *) atts[i+1] encoding:NSUTF8StringEncoding];
				break;
			}
		}
			
		return;
		
	} else if (textView.currentElement != nil){
		[textView saveCurrentElement];
	}
	
	// first, insert newlines/paragraphs where needed
	
	if (!strcmp((char *)name, "blockquote") || !strcmp((char *)name, "img")){
		SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];
		element.style = SMFancyTextElementStyleNewLine;
		textView.currentElement = element;
		[textView saveCurrentElement];
	}
	
	SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];

	if (!strcmp((char *)name, "strong") || !strcmp((char *)name, "b")){
		element.style = SMFancyTextElementStyleBold;
	} else if (!strcmp((char *)name, "em") || !strcmp((char *)name, "i")){
		element.style = SMFancyTextElementStyleItalic;
	} else if (!strcmp((char *)name, "li")){
		element.style = SMFancyTextElementStyleListItem;
	} else if (!strcmp((char *)name, "ul")){
		element.style = SMFancyTextElementStyleNewLine;
	} else if (!strcmp((char *)name, "blockquote")){
		element.style = SMFancyTextElementStyleBlockQuote;
	} else if (!strcmp((char *)name, "a")){
		element.style = SMFancyTextElementStyleLink;
		for (NSInteger i = 0; i < sizeof(atts); i++){
			if (!strcmp((char *)atts[i], "href")){
				element.link = [NSString stringWithCString:(const char *) atts[i+1] encoding:NSUTF8StringEncoding];
				break;
			}
		}
	} else if (!strcmp((char *)name, "img")){
		element.style = SMFancyTextElementStyleImage;
		for (NSInteger i = 0; i < sizeof(atts); i++){
			if (!strcmp((char *)atts[i], "src")){
				element.link = [NSString stringWithCString:(const char *) atts[i+1] encoding:NSUTF8StringEncoding];
				break;
			}
		}
	} else {
		element.style = SMFancyTextElementStyleNormal;
	}
		
	textView.currentElement = element;
}

void endElement (void * ctx, const xmlChar * name)
{
	SMFancyText *textView = (SMFancyText *) ctx;
	[textView saveCurrentElement];
	
	if (!strcmp((char *) name, "p") || !strcmp((char *) name, "li") || !strcmp((char *) name, "ul")){
		SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];
		element.style = SMFancyTextElementStyleNewLine;
		textView.currentElement = element;
		[textView saveCurrentElement];
	} else if (!strcmp((char *) name, "blockquote")){
		SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];
		element.style = SMFancyTextElementStyleParagraphBreak;
		textView.currentElement = element;
		[textView saveCurrentElement];
	}
}

void charactersFound (void * ctx, const xmlChar * ch, int len)
{
	SMFancyText *textView = (SMFancyText *) ctx;
	
	if (textView.currentElement == nil){
		SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];
		element.style = SMFancyTextElementStyleNormal;
		textView.currentElement = element;
	}
	
	if (textView.currentElement.style == SMFancyTextElementStyleListItem){
		textView.currentElement.text = [NSString stringWithFormat:@"%@ %@", HTMLBullet, [NSString stringWithCString:(const char *) ch encoding:NSUTF8StringEncoding]];
	} else {
		textView.currentElement.text = [NSString stringWithCString:(const char *) ch encoding:NSUTF8StringEncoding];
	}
}

void endDocument (void * ctx)
{
	SMFancyText *textView = (SMFancyText *) ctx;
	[textView setNeedsDisplay];
}

void errorEncountered (void *ctx, const char *msg, ...)
{
	
}

static htmlSAXHandler simpleSAXHandlerStruct = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    NULL,                       /* startDocument */
    endDocument,                       /* endDocument */
    startElement,                       /* startElement*/
    endElement,                       /* endElement */
    NULL,                       /* reference */
    charactersFound,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncountered,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    NULL,                       /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,             //
    NULL,
    NULL,						/* startElementNs */
    NULL,						/* endElementNs */
    NULL,                       /* serror */
};

@end


#pragma mark -
#pragma mark SMFancyTextElement

@implementation SMFancyTextElement

@synthesize text, style, link, imageName;

- (NSString *) description
{
	return [NSString stringWithFormat:@"SMFancyTextElement ::  %@ - %d", text, style];
}

- (void) dealloc
{
	self.text = nil;
	self.style = -1;
	self.link = nil;
	self.imageName = nil;
	
	[super dealloc];
}

@end