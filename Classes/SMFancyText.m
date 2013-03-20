//
//  SMFancyText.m
//  SMFancyText
//
//  Created by Simon Maddox on 12/08/2010.
//  Copyright 2010 Sensible Duck Ltd. All rights reserved.
//

#import "SMFancyText.h"
#import "SMFancyTextElement.h"

static NSString * const SMHTMLBullet = @"•";
const CGFloat SMFontSize = 14.0f;
const CGFloat SMLinkRed = 65.0f;
const CGFloat SMLinkGreen = 123.0f;
const CGFloat SMLinkBlue = 192.0f;

#pragma mark - LibXML Headers

void startElementSAX (void * ctx, const xmlChar * name, const xmlChar ** atts);
void endElementSAX (void * ctx, const xmlChar * name);
void charactersFound (void * ctx, const xmlChar * ch, int len);
void endDocumentSAX (void * ctx);
void errorEncountered (void *ctx, const char *msg, ...);

static xmlSAXHandler simpleSAXHandlerStruct;

#pragma mark - SMFancyText

@implementation SMFancyText

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _elements = [[NSMutableArray array] retain];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
        _elements = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

	_currentPosition = CGPointMake(0, 0);
	
	CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
	
	if (!self.textColor) self.textColor = [UIColor blackColor];
	
	CGContextSetFillColorWithColor(graphicsContext, [self.textColor CGColor]);
	
    for (SMFancyTextElement *element in self.elements) {

		UIFont *font = nil;
		
		switch (element.style) {
			case SMFancyTextElementStyleBold:
			case SMFancyTextElementStyleBlockQuote:
				font = [UIFont boldSystemFontOfSize:SMFontSize];
				break;
			case SMFancyTextElementStyleItalic:
				font = [UIFont italicSystemFontOfSize:SMFontSize];
				break;
			default:
				font = [UIFont systemFontOfSize:SMFontSize];
				break;
		}
		
		if (element.style == SMFancyTextElementStyleBlockQuote) {
			CGContextFillRect(graphicsContext, CGRectMake(0, _currentPosition.y - 5, rect.size.width, 2));
		}

		if (element.style == SMFancyTextElementStyleParagraphBreak) {
			_currentPosition.x = 0;
			_currentPosition.y = _currentPosition.y + (18 * 2);
		} else if (element.style == SMFancyTextElementStyleNewLine) {
			_currentPosition.x = 0;
			_currentPosition.y = _currentPosition.y + 18;
		} else {
			[self drawString:element.text withFont:font atPoint:_currentPosition inRect:rect recursive:YES style:element.style withLink:element.link image:element.imageName];
		}
		
		if (element.style == SMFancyTextElementStyleBlockQuote) {
			CGContextFillRect(graphicsContext, CGRectMake(0, _currentPosition.y + 20, rect.size.width, 2));
		}
	}
}

- (void)drawString:(NSString *)string
		  withFont:(UIFont *)font
		   atPoint:(CGPoint)point
			inRect:(CGRect)rect
		 recursive:(BOOL)recursive
			 style:(SMFancyTextElementStyle)style
		  withLink:(NSString *)link
			 image:(NSString *)image {
	
	if (point.x == 0) {
		string = [self removeLeadingWhiteSpaceFromString:string];
	}
	
	CGSize size = [string sizeWithFont:font];
	
	if (point.x + size.width > rect.size.width) {
		if (recursive) {
			NSArray *words = [string componentsSeparatedByString:@" "];
			for (NSUInteger i = 0; i < [words count]; ++i) {
				if (i < [words count] - 1) {
					[self drawString:[NSString stringWithFormat:@"%@ ", [words objectAtIndex:i]] withFont:font atPoint:_currentPosition inRect:rect recursive:NO style:style withLink:link image:image];
				} else {
					[self drawString:[NSString stringWithFormat:@"%@", [words objectAtIndex:i]] withFont:font atPoint:_currentPosition inRect:rect recursive:NO style:style withLink:link image:image];
				}
			}
			return;
		} else {
			[self drawString:string withFont:font atPoint:CGPointMake(0, _currentPosition.y + size.height) inRect:rect recursive:NO style:style withLink:link image:image];
			return;
		}
	}
	
	if (size.width <= rect.size.width && _currentPosition.x + size.width > rect.size.width) {
		_currentPosition.y += size.height;
		_currentPosition.x = 0;
	}
	
	CGRect theRect = CGRectMake(_currentPosition.x, _currentPosition.y, size.width, size.height);
		
	if (link != nil || image != nil) {
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		if (style == SMFancyTextElementStyleLink) {
			if ([_delegate respondsToSelector:@selector(fancyText:linkPressed:)]) {
				
				UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
				[button setFrame:theRect];
				[button setTitle:link forState:UIControlStateNormal];
				[button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
				[button addTarget:self action:@selector(linkTouchUp:) forControlEvents:UIControlEventTouchUpInside];
				[button addTarget:self action:@selector(linkPressed:) forControlEvents:UIControlEventTouchDown];
				[self addSubview:button];
				
				CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:SMLinkRed / 255.0 green:SMLinkGreen / 255.0 blue:SMLinkBlue / 255.0 alpha:1] CGColor]);
				CGContextFillRect(context, CGRectMake(_currentPosition.x, _currentPosition.y + (theRect.size.height - 2), theRect.size.width, 1));
				[string drawInRect:theRect withFont:font];
				CGContextSetFillColorWithColor(context, [self.textColor CGColor]);
				
			}
		} else if (style == SMFancyTextElementStyleImage) {
			
			UIImage *theImage = [UIImage imageNamed:image];
			[theImage drawInRect:CGRectMake((self.frame.size.width / 2) - (theImage.size.width / 2), _currentPosition.y, theImage.size.width, theImage.size.height)];
			_currentPosition.y += theImage.size.height;
			
		} else if (style == SMFancyTextElementStyleImageLink) {
			
			UIImage *theImage = [UIImage imageNamed:image];
			
			CGRect imageFrame = CGRectMake((self.frame.size.width / 2) - (theImage.size.width / 2), _currentPosition.y, theImage.size.width, theImage.size.height);
			[theImage drawInRect:imageFrame];
			
			UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
			[button setFrame:imageFrame];
			[button setTitle:link forState:UIControlStateNormal];
			[button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
			[button addTarget:_delegate action:@selector(linkPressed:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
			
			_currentPosition.y += theImage.size.height;
			
		}
	} else {
		[string drawInRect:theRect withFont:font];
	}
		
	_currentPosition = CGPointMake(_currentPosition.x + size.width, _currentPosition.y);
}

- (void)linkPressed:(UIButton *)button {
	[button setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2]];
}

- (void)linkTouchUp:(UIButton *)button {
	[button setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0]];
	[_delegate fancyText:self linkPressed:button];
}

- (void)setText:(NSString *)newText {
	
	NSData *data = [[NSString stringWithFormat:@"<SMFancyText>%@</SMFancyText>", [newText stringByReplacingOccurrencesOfString:@"\n" withString:@""]] dataUsingEncoding:NSUTF8StringEncoding];

	htmlParserCtxtPtr context = htmlCreatePushParserCtxt(&simpleSAXHandlerStruct, self, NULL, 0, NULL, XML_CHAR_ENCODING_UTF8);
	htmlParseChunk(context, (const char *)[data bytes], [data length], 0);
	htmlFreeParserCtxt(context);
	context = NULL;
}

- (NSString *)removeLeadingWhiteSpaceFromString:(NSString *)string {
	if (!string) return nil;

	NSMutableString *mutableString = [NSMutableString stringWithString:string];

	NSInteger whitespaceCount = 0;

	for (NSInteger i = 0; i < string.length; ++i) {
		if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[mutableString characterAtIndex:i]]) {
			whitespaceCount = i;
		} else {
			break;
		}
	}

	return [string substringFromIndex:whitespaceCount];
}

- (void)dealloc {

	[_currentElement release];
	[_elements release];
	[_textColor release];

	_currentElement = nil;
	_elements = nil;
	_textColor = nil;

    [super dealloc];
}

- (void)saveCurrentElement {
	if (!self.currentElement) return;
	[self.elements addObject:self.currentElement];
	self.currentElement = nil;
}

#pragma mark - LibXML

void startElement(void *ctx, const xmlChar *name, const xmlChar **atts) {
	
	SMFancyText *textView = (SMFancyText *) ctx;
	
	if (textView.currentElement.style == SMFancyTextElementStyleLink && !strcmp((char *)name, "img")) {
		textView.currentElement.style = SMFancyTextElementStyleImageLink;
		
		for (NSUInteger i = 0; i < sizeof(atts); ++i) {
			if (!xmlStrcmp(atts[i], (unsigned char *)"src")) {
				textView.currentElement.imageName = [NSString stringWithCString:(const char *) atts[i+1] encoding:NSUTF8StringEncoding];
				break;
			}
		}
			
		return;
		
	} else if (textView.currentElement != nil) {
		[textView saveCurrentElement];
	}
	
	// first, insert newlines/paragraphs where needed
	
	if (!strcmp((char *)name, "blockquote") || !strcmp((char *)name, "img")) {
		textView.currentElement = [SMFancyTextElement textElementWithStyle:SMFancyTextElementStyleNewLine];
		[textView saveCurrentElement];
	}
	
	SMFancyTextElement *element = [SMFancyTextElement textElement];

	if (!xmlStrcmp(name, (unsigned char *)"strong") ||
		!xmlStrcmp(name, (unsigned char *)"b")) {
		element.style = SMFancyTextElementStyleBold;
	} else if (!xmlStrcmp(name, (unsigned char *)"em") ||
			   !xmlStrcmp(name, (unsigned char *)"i")) {
		element.style = SMFancyTextElementStyleItalic;
	} else if (!xmlStrcmp(name, (unsigned char *)"li")) {
		element.style = SMFancyTextElementStyleListItem;
	} else if (!xmlStrcmp(name, (unsigned char *)"ul")) {
		element.style = SMFancyTextElementStyleNewLine;
	} else if (!xmlStrcmp(name, (unsigned char *)"blockquote")) {
		element.style = SMFancyTextElementStyleBlockQuote;
	} else if (!xmlStrcmp(name, (unsigned char *)"a")) {
		element.style = SMFancyTextElementStyleLink;
		
		for (NSUInteger i = 0; i < sizeof(atts); ++i) {
			if (!xmlStrcmp(atts[i], (unsigned char *)"href")) {
				element.link = [NSString stringWithCString:(const char *) atts[i+1] encoding:NSUTF8StringEncoding];
				break;
			}
		}
	} else if (!xmlStrcmp(name, (unsigned char *)"img")) {
		element.style = SMFancyTextElementStyleImage;
		
		for (NSUInteger i = 0; i < sizeof(atts); ++i) {
			if (!xmlStrcmp(atts[i], (unsigned char *)"src")) {
				element.link = [NSString stringWithCString:(const char *) atts[i+1] encoding:NSUTF8StringEncoding];
				break;
			}
		}
	}
		
	textView.currentElement = element;
}

void endElement(void *ctx, const xmlChar *name) {
	
	SMFancyText *textView = (SMFancyText *) ctx;
	[textView saveCurrentElement];
	
	if (!xmlStrcmp(name, (unsigned char *)"p") ||
		!xmlStrcmp(name, (unsigned char *)"li") ||
		!xmlStrcmp(name, (unsigned char *)"ul")) {
		textView.currentElement = [SMFancyTextElement textElementWithStyle:SMFancyTextElementStyleNewLine];
		[textView saveCurrentElement];
	} else if (!xmlStrcmp(name, (unsigned char *)"blockquote")) {
		textView.currentElement = [SMFancyTextElement textElementWithStyle:SMFancyTextElementStyleParagraphBreak];
		[textView saveCurrentElement];
	}
}

void charactersFound(void *ctx, const xmlChar *ch, int len) {
	
	SMFancyText *textView = (SMFancyText *) ctx;
	
	if (!textView.currentElement) textView.currentElement = [SMFancyTextElement textElement];
	
	if (textView.currentElement.style == SMFancyTextElementStyleListItem) {
		textView.currentElement.text = [NSString stringWithFormat:@"%@ %@", SMHTMLBullet, [NSString stringWithCString:(const char *) ch encoding:NSUTF8StringEncoding]];
	} else {
		textView.currentElement.text = [NSString stringWithCString:(const char *) ch encoding:NSUTF8StringEncoding];
	}
}

void endDocument(void *ctx) {
	SMFancyText *textView = (SMFancyText *)ctx;
	[textView setNeedsDisplay];
}

void errorEncountered(void *ctx, const char *msg, ...) {
	
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
    endDocument,                /* endDocument */
    startElement,               /* startElement*/
    endElement,                 /* endElement */
    NULL,                       /* reference */
    charactersFound,            /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncountered,           /* error */
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
