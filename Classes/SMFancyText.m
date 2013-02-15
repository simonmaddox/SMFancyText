//
//  SMFancyText.m
//  SMFancyText
//
//  Created by Simon Maddox on 12/08/2010.
//  Copyright 2010 Sensible Duck Ltd. All rights reserved.
//

#import "SMFancyText.h"
#import "SMFancyTextElement.h"

#define HTMLBullet @"•"

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
	
	CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
	
	if (self.textColor == nil) {
		self.textColor = [UIColor blackColor];
	}
	
	CGContextSetFillColorWithColor(graphicsContext, [self.textColor CGColor]);
	
    for (NSUInteger i = 0; i < [self.elements count]; ++i) {
		UIFont *font = nil;
		
		switch ((SMFancyTextElementStyle)[[self.elements objectAtIndex:i] style]) {
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
		
		if ([[self.elements objectAtIndex:i] style] == SMFancyTextElementStyleBlockQuote) {
			CGContextFillRect(graphicsContext, CGRectMake(0, _currentPosition.y - 5, rect.size.width, 2));
		}

		if ([[self.elements objectAtIndex:i] style] == SMFancyTextElementStyleParagraphBreak) {
			_currentPosition.x = 0;
			_currentPosition.y = _currentPosition.y + (18 * 2);
		} else if ([[self.elements objectAtIndex:i] style] == SMFancyTextElementStyleNewLine) {
			_currentPosition.x = 0;
			_currentPosition.y = _currentPosition.y + 18;
		} else {
			[self drawString:[[self.elements objectAtIndex:i] text] withFont:font atPoint:_currentPosition inRect:rect recursive:YES style:[[self.elements objectAtIndex:i] style] withLink:[[self.elements objectAtIndex:i] link] image:[[self.elements objectAtIndex:i] imageName]];
		}
		
		if ([[self.elements objectAtIndex:i] style] == SMFancyTextElementStyleBlockQuote) {
			CGContextFillRect(graphicsContext, CGRectMake(0, _currentPosition.y + 20, rect.size.width, 2));
		}
	}
}

- (void)drawString:(NSString *)string withFont:(UIFont *)font atPoint:(CGPoint)point inRect:(CGRect)rect recursive:(BOOL)recursive style:(SMFancyTextElementStyle)style withLink:(NSString *)link image:(NSString *)image {
	
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
		CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
		
		if (style == SMFancyTextElementStyleLink) {
			if ([_delegate respondsToSelector:@selector(fancyText:linkPressed:)]) {
				UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
				[button setFrame:theRect];
				[button setTitle:link forState:UIControlStateNormal];
				[button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
				[button addTarget:self action:@selector(linkTouchUp:) forControlEvents:UIControlEventTouchUpInside];
				[button addTarget:self action:@selector(linkPressed:) forControlEvents:UIControlEventTouchDown];
				[self addSubview:button];
				
				CGContextSetFillColorWithColor(graphicsContext, [[UIColor colorWithRed:65.0/255.0 green:123.0/255.0 blue:192.0/255.0 alpha:1] CGColor]);
				CGContextFillRect(graphicsContext, CGRectMake(_currentPosition.x, _currentPosition.y + (theRect.size.height - 2), theRect.size.width, 1));
				[string drawInRect:theRect withFont:font];
				CGContextSetFillColorWithColor(graphicsContext, [self.textColor CGColor]);
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

	_context = htmlCreatePushParserCtxt(&simpleSAXHandlerStruct, self, NULL, 0, NULL, XML_CHAR_ENCODING_UTF8);
	htmlParseChunk(_context, (const char *)[data bytes], [data length], 0);
	htmlFreeParserCtxt(_context);
	_context = NULL;
}

- (NSString *)removeLeadingWhiteSpaceFromString:(NSString *)string {

	if (string == nil) {
		return nil;
	}
	
	NSMutableString *mutableString = [NSMutableString stringWithString:string];

	[mutableString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	return [NSString stringWithString:mutableString];
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
	if (self.currentElement == nil) {
		return;
	}
	[self.elements addObject:self.currentElement];
	self.currentElement = nil;
}

#pragma mark - LibXML

void startElement(void *ctx, const xmlChar *name, const xmlChar **atts) {
	
	SMFancyText *textView = (SMFancyText *) ctx;
	
	if (textView.currentElement.style == SMFancyTextElementStyleLink && !strcmp((char *)name, "img")) {
		textView.currentElement.style = SMFancyTextElementStyleImageLink;
		
		for (NSUInteger i = 0; i < sizeof(atts); ++i) {
			if (!strcmp((char *)atts[i], "src")) {
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
		SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];
		element.style = SMFancyTextElementStyleNewLine;
		textView.currentElement = element;
		[textView saveCurrentElement];
	}
	
	SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];

	if (!strcmp((char *)name, "strong") || !strcmp((char *)name, "b")) {
		element.style = SMFancyTextElementStyleBold;
	} else if (!strcmp((char *)name, "em") || !strcmp((char *)name, "i")) {
		element.style = SMFancyTextElementStyleItalic;
	} else if (!strcmp((char *)name, "li")) {
		element.style = SMFancyTextElementStyleListItem;
	} else if (!strcmp((char *)name, "ul")) {
		element.style = SMFancyTextElementStyleNewLine;
	} else if (!strcmp((char *)name, "blockquote")) {
		element.style = SMFancyTextElementStyleBlockQuote;
	} else if (!strcmp((char *)name, "a")) {
		element.style = SMFancyTextElementStyleLink;
		for (NSUInteger i = 0; i < sizeof(atts); ++i) {
			if (!strcmp((char *)atts[i], "href")) {
				element.link = [NSString stringWithCString:(const char *) atts[i+1] encoding:NSUTF8StringEncoding];
				break;
			}
		}
	} else if (!strcmp((char *)name, "img")) {
		element.style = SMFancyTextElementStyleImage;
		for (NSUInteger i = 0; i < sizeof(atts); ++i) {
			if (!strcmp((char *)atts[i], "src")) {
				element.link = [NSString stringWithCString:(const char *) atts[i+1] encoding:NSUTF8StringEncoding];
				break;
			}
		}
	} else {
		element.style = SMFancyTextElementStyleNormal;
	}
		
	textView.currentElement = element;
}

void endElement(void *ctx, const xmlChar *name) {
	
	SMFancyText *textView = (SMFancyText *) ctx;
	[textView saveCurrentElement];
	
	if (!strcmp((char *) name, "p") || !strcmp((char *) name, "li") || !strcmp((char *) name, "ul")) {
		SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];
		element.style = SMFancyTextElementStyleNewLine;
		textView.currentElement = element;
		[textView saveCurrentElement];
	} else if (!strcmp((char *) name, "blockquote")) {
		SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];
		element.style = SMFancyTextElementStyleParagraphBreak;
		textView.currentElement = element;
		[textView saveCurrentElement];
	}
}

void charactersFound(void *ctx, const xmlChar *ch, int len) {
	
	SMFancyText *textView = (SMFancyText *) ctx;
	
	if (textView.currentElement == nil) {
		SMFancyTextElement *element = [[[SMFancyTextElement alloc] init] autorelease];
		element.style = SMFancyTextElementStyleNormal;
		textView.currentElement = element;
	}
	
	if (textView.currentElement.style == SMFancyTextElementStyleListItem) {
		textView.currentElement.text = [NSString stringWithFormat:@"%@ %@", HTMLBullet, [NSString stringWithCString:(const char *) ch encoding:NSUTF8StringEncoding]];
	} else {
		textView.currentElement.text = [NSString stringWithCString:(const char *) ch encoding:NSUTF8StringEncoding];
	}
}

void endDocument(void *ctx) {
	SMFancyText *textView = (SMFancyText *) ctx;
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
