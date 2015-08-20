//
//  VideoBuilder
//  From VideoBeautify
//
//  Created by Johnny Xu(徐景周) on 7/23/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "VideoBuilder.h"
#import "GPUImage.h"
#import <CoreText/CoreText.h>
#import "CommonDefine.h"

NSString * const kStrokeAnimation = @"StrokeAnimation";
NSString * const kEmitterAnimation = @"EmitterAnimation";
NSString * const kSparkCellKey = @"SparkCell";
NSString * const kSmokeCellKey = @"SmokeCell";


#pragma mark - Private property
@interface VideoBuilder ()

@property (nonatomic, readwrite, retain) AVComposition *composition;
@property (nonatomic, readwrite, retain) AVVideoComposition *videoComposition;
@property (nonatomic, readwrite, retain) AVAudioMix *audioMix;
@property (nonatomic, readwrite, retain) AVPlayerItem *playerItem;
@property (nonatomic, readwrite, retain) AVSynchronizedLayer *synchronizedLayer;

@end


#pragma mark - Public property
@implementation VideoBuilder

// Configuration
@synthesize clips = _clips, clipTimeRanges = _clipTimeRanges;
@synthesize commentary = _commentary, commentaryStartTime = _commentaryStartTime;
@synthesize transitionType = _transitionType, transitionDuration = _transitionDuration;
@synthesize titleText = _titleText;

// Composition objects.
@synthesize composition = _composition;
@synthesize videoComposition =_videoComposition;
@synthesize audioMix = _audioMix;
@synthesize playerItem = _playerItem;
@synthesize synchronizedLayer = _synchronizedLayer;


#pragma mark - Initialize
- (id)init
{
	if (self = [super init])
    {
		_commentaryStartTime = CMTimeMake(0, 1); // Default start time for the commentary is 0 seconds.
		
		_transitionDuration = CMTimeMake(1, 1); // Default transition duration is one second.
		
		// just until we have the UI for this wired up
		NSMutableArray *clipTimeRanges = [[NSMutableArray alloc] initWithCapacity:3];
		CMTimeRange defaultTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(5, 1));
		NSValue *defaultTimeRangeValue = [NSValue valueWithCMTimeRange:defaultTimeRange];
		[clipTimeRanges addObject:defaultTimeRangeValue];
		[clipTimeRanges addObject:defaultTimeRangeValue];
		[clipTimeRanges addObject:defaultTimeRangeValue];
		_clipTimeRanges = clipTimeRanges;
	}
    
	return self;
}

#pragma mark - BuildEmitterRing
static CGImageRef createStarImage(CGFloat radius)
{
	int i, count = 5;
    
#if TARGET_OS_IPHONE
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
#else // not TARGET_OS_IPHONE
	CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
#endif // not TARGET_OS_IPHONE
    
	CGImageRef image = NULL;
	size_t width = 2*radius;
	size_t height = 2*radius;
	size_t bytesperrow = width * 4;
	CGContextRef context = CGBitmapContextCreate((void *)NULL, width, height, 8, bytesperrow, colorspace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
	CGContextClearRect(context, CGRectMake(0, 0, 2*radius, 2*radius));
	CGContextSetLineWidth(context, radius / 15.0);
	
	for( i = 0; i < 2 * count; i++ )
    {
		CGFloat angle = i * M_PI / count;
		CGFloat pointradius = (i % 2) ? radius * 0.37 : radius * 0.95;
		CGFloat x = radius + pointradius * cos(angle);
		CGFloat y = radius + pointradius * sin(angle);
		if (i == 0)
			CGContextMoveToPoint(context, x, y);
		else
			CGContextAddLineToPoint(context, x, y);
	}
	CGContextClosePath(context);
	
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
	CGContextDrawPath(context, kCGPathFillStroke);
	CGColorSpaceRelease(colorspace);
	image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
    
	return image;
}

- (CAEmitterLayer*) buildEmitterRing:(CGSize)viewBounds
{
    // Create the emitter layer
	CAEmitterLayer *ringEmitter = [CAEmitterLayer layer];
	
	// Cells spawn in a 50pt circle around the position
	ringEmitter.emitterPosition = CGPointMake(arc4random()%(int)viewBounds.width, arc4random()%(int)viewBounds.height);
	ringEmitter.emitterSize	= CGSizeMake(50, 0);
	ringEmitter.emitterMode	= kCAEmitterLayerOutline;
	ringEmitter.emitterShape	= kCAEmitterLayerCircle;
	ringEmitter.renderMode		= kCAEmitterLayerBackToFront;
    
	// Create the fire emitter cell
	CAEmitterCell* ring = [CAEmitterCell emitterCell];
	[ring setName:@"ring"];
	
	ring.birthRate			= 5;
	ring.velocity			= 250;
	ring.scale				= 0.5;
	ring.scaleSpeed			=-0.2;
	ring.greenSpeed			=-0.2;	// shifting to green
	ring.redSpeed			=-0.5;
	ring.blueSpeed			=-0.5;
	ring.lifetime			= 2;
	
	ring.color = [[UIColor whiteColor] CGColor];
	ring.contents = (id) [[UIImage imageNamed:@"DazTriangle"] CGImage];
	
    
	CAEmitterCell* circle = [CAEmitterCell emitterCell];
	[circle setName:@"circle"];
	
	circle.birthRate		= 5;			// every triangle creates
	circle.emissionLongitude = M_PI * 0.5;	// sideways to triangle vector
	circle.velocity			= 50;
	circle.scale			= 0.5;
	circle.scaleSpeed		=-0.2;
	circle.greenSpeed		=-0.1;
	circle.redSpeed			=-0.2;
	circle.blueSpeed		= 0.1;
	circle.alphaSpeed		=-0.2;
	circle.lifetime			= 4;
	
	circle.color = [[UIColor whiteColor] CGColor];
	circle.contents = (id) [[UIImage imageNamed:@"DazRing"] CGImage];
    
    
	CAEmitterCell* star = [CAEmitterCell emitterCell];
	[star setName:@"star"];
	
	star.birthRate		= 5;	// every triangle creates
	star.velocity		= 100;
	star.zAcceleration  = -1;
	star.emissionLongitude = -M_PI;	// back from triangle vector
	star.scale			= 0.5;
	star.scaleSpeed		=-0.2;
	star.greenSpeed		=-0.1;
	star.redSpeed		= 0.4;	// shifting to red
	star.blueSpeed		=-0.1;
	star.alphaSpeed		=-0.2;
	star.lifetime		= 2;
	
	star.color = [[UIColor whiteColor] CGColor];
	star.contents = (id) [[UIImage imageNamed:@"DazStarOutline"] CGImage];
	
	// First traigles are emitted, which then spawn circles and star along their path
	ringEmitter.emitterCells = [NSArray arrayWithObject:ring];
	ring.emitterCells = [NSArray arrayWithObjects:circle, star, nil];
    
    
    CABasicAnimation *burst = [CABasicAnimation animationWithKeyPath:@"emitterCells.ring.birthRate"];
	burst.fromValue			= [NSNumber numberWithFloat: 100.0];	// short but intense burst
	burst.toValue			= [NSNumber numberWithFloat: 0.0];		// each birth creates 20 aditional cells!
	burst.duration			= 0.5;
	burst.timingFunction	= [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    burst.repeatCount = 5;
	
	[ringEmitter addAnimation:burst forKey:@"burst"];
    
	// Move to point
//	[CATransaction begin];
//	[CATransaction setDisableActions: YES];
//	ringEmitter.emitterPosition	= CGPointMake(viewBounds.width/2, viewBounds.height/2);
//	[CATransaction commit];
    
    return ringEmitter;
}

#pragma mark - BuildEmitterSnow
- (CAEmitterLayer*) buildEmitterSnow:(CGSize)viewBounds
{
    // Configure the particle emitter to the top edge of the screen
	CAEmitterLayer *snowEmitter = [CAEmitterLayer layer];
	snowEmitter.emitterPosition = CGPointMake(viewBounds.width / 2.0, viewBounds.height);
	snowEmitter.emitterSize		= CGSizeMake(viewBounds.width * 2.0, 0.0);
	
	// Spawn points for the flakes are within on the outline of the line
	snowEmitter.emitterMode		= kCAEmitterLayerOutline;
	snowEmitter.emitterShape	= kCAEmitterLayerLine;
	
	// Configure the snowflake emitter cell
	CAEmitterCell *snowflake = [CAEmitterCell emitterCell];
	
	snowflake.birthRate		= 1.0;
	snowflake.lifetime		= 60.0;
	
	snowflake.velocity		= 10;				// falling down slowly
	snowflake.velocityRange = 10;
	snowflake.yAcceleration = -30;
	snowflake.emissionRange = 0.5 * M_PI;		// some variation in angle
	snowflake.spinRange		= 0.25 * M_PI;		// slow spin
	
	snowflake.contents		= (id) [[UIImage imageNamed:@"DazFlake"] CGImage];
	snowflake.color			= [[UIColor colorWithRed:0.600 green:0.658 blue:0.743 alpha:1.000] CGColor];
    
	// Make the flakes seem inset in the background
	snowEmitter.shadowOpacity = 1.0;
	snowEmitter.shadowRadius  = 0.0;
	snowEmitter.shadowOffset  = CGSizeMake(0.0, 1.0);
	snowEmitter.shadowColor   = [[UIColor whiteColor] CGColor];
	
	// Add everything to our backing layer below the UIContol defined in the storyboard
	snowEmitter.emitterCells = [NSArray arrayWithObject:snowflake];
    
	return snowEmitter;
}

// Snow effect 2
- (CAEmitterLayer*) buildEmitterSnow2:(CGSize)viewBounds
{
    CAEmitterLayer *parentLayer = [CAEmitterLayer layer];
    parentLayer.emitterPosition = CGPointMake(viewBounds.width/2.0, viewBounds.height+30);
    parentLayer.emitterSize		= CGSizeMake(viewBounds.width*2, 0);
    
    // Spawn points for the flakes are within on the outline of the line
    parentLayer.emitterMode		= kCAEmitterLayerOutline;
	parentLayer.emitterShape	= kCAEmitterLayerLine;
    
    parentLayer.shadowOpacity = 1.0;
	parentLayer.shadowRadius  = 0.0;
	parentLayer.shadowOffset  = CGSizeMake(0.0, 1.0);
	parentLayer.shadowColor   = [[UIColor whiteColor] CGColor];
    parentLayer.seed = (arc4random()%100)+1;
    
    CAEmitterCell* containerLayer = [CAEmitterCell emitterCell];
	containerLayer.birthRate = 3;
	containerLayer.velocity	= -1;
	containerLayer.lifetime	= 0.4;
    containerLayer.name = @"containerLayer";
    
    NSMutableArray *snowArray = [NSMutableArray array];
    for (int i = 1; i <= 13; i++)
    {
        NSString *imageName = [NSString stringWithFormat:@"snow%i",i];
        UIImage *image = [UIImage imageNamed:imageName];
        if (image)
        {
            [snowArray addObject:[self createFlowerLayer:image]];
        }
    }
    
    containerLayer.emitterCells = @[snowArray[0], snowArray[1], snowArray[3], snowArray[4], snowArray[5], snowArray[6], snowArray[7], snowArray[8], snowArray[9], snowArray[10], snowArray[11], snowArray[12]];
    parentLayer.emitterCells = @[containerLayer];
    
    return parentLayer;
}

-(CAEmitterCell *) createSnowLayer:(UIImage *)image
{
    CAEmitterCell *cellLayer = [CAEmitterCell emitterCell];
    
    cellLayer.birthRate		= 1;
    cellLayer.lifetime		= 20;
	
	cellLayer.velocity		= -100;				// falling down slowly
	cellLayer.velocityRange = 0;
	cellLayer.yAcceleration = 2;
    cellLayer.emissionRange = 0.5 * M_PI;		// some variation in angle
    cellLayer.spinRange		= 0.5 * M_PI;		// slow spin
    cellLayer.scale = 0.2;
    cellLayer.contents		= (id)[image CGImage];
    
    cellLayer.color			= [[UIColor whiteColor] CGColor];
    
    return cellLayer;
}

#pragma mark - BuildEmitterBlackWhiteDot
-(CAEmitterCell *) createBlackWhiteDots:(BOOL)isBlack
{
    CAEmitterCell* Dots = [CAEmitterCell emitterCell];
    Dots.birthRate = 10;
    Dots.lifetime = 0.5;
    Dots.scale = 0.3;
    Dots.scaleRange = 0.3;
	Dots.scaleSpeed = -0.25;
    
    Dots.spin = 0.384;
	Dots.spinRange = 0.925;
	Dots.emissionLatitude = 1.745;
	Dots.emissionLongitude = 1.745;
	Dots.emissionRange = 3.491;
    
    UIImage *image = [UIImage imageNamed:@"dot"];
    if (isBlack)
    {
        Dots.color = [[UIColor blackColor] CGColor];
    }
    else
    {
        Dots.color = [[UIColor whiteColor] CGColor];
    }
    Dots.contents = (id)[image CGImage];
    
    Dots.contentsRect = CGRectMake(0.00, 0.00, 1.00, 1.00);
	Dots.magnificationFilter = kCAFilterTrilinear;
	Dots.minificationFilter = kCAFilterLinear;

    return Dots;
}

- (CAEmitterLayer*) buildEmitterBlackWhiteDot:(CGSize)viewBounds positon:(CGPoint)postion startTime:(NSTimeInterval)startTime
{
    CAEmitterLayer* dotsEmitter = [CAEmitterLayer layer];
    dotsEmitter.emitterPosition = postion;
    dotsEmitter.emitterSize = CGSizeMake(viewBounds.width, viewBounds.height/12);
    dotsEmitter.renderMode = kCAEmitterLayerBackToFront;
    dotsEmitter.emitterShape = kCAEmitterLayerCircle;
    dotsEmitter.emitterMode = kCAEmitterLayerSurface;
    dotsEmitter.beginTime = startTime;

    CAEmitterCell* blackDots = [self createBlackWhiteDots:TRUE];
    CAEmitterCell* whiteDots = [self createBlackWhiteDots:FALSE];
    
    dotsEmitter.emitterCells = [NSArray arrayWithObjects:blackDots, whiteDots, nil];

    return dotsEmitter;
}

#pragma mark - BuildEmitterDot
- (CAEmitterLayer*) buildEmitterMoveDot:(CGSize)viewBounds position:(CGPoint)position
{
    // configure the emitter layer
    CAEmitterLayer* dotsEmitter = [CAEmitterLayer layer];
    dotsEmitter.emitterPosition = position; //CGPointMake(160, 240);
    dotsEmitter.emitterSize = CGSizeMake(viewBounds.width, viewBounds.height);
    NSLog(@"width = %f, height = %f", dotsEmitter.emitterSize.width, dotsEmitter.emitterSize.height);
    dotsEmitter.renderMode = kCAEmitterLayerPoints;
    dotsEmitter.emitterShape = kCAEmitterLayerRectangle;
    dotsEmitter.emitterMode = kCAEmitterLayerUnordered;
    
    CAEmitterCell* dots = [CAEmitterCell emitterCell];
    dots.birthRate = 5;
    dots.lifetime = 5;
    dots.lifetimeRange = 0.5;
    
    dots.color = [[UIColor colorWithRed:0.8 green:0.6 blue:0.70 alpha:0.6] CGColor];
	dots.redRange = 0.9;
	dots.greenRange = 0.8;
	dots.blueRange = 0.7;
	dots.alphaRange = 0.8;
    
	dots.redSpeed = 0.92;
	dots.greenSpeed = 0.84;
	dots.blueSpeed = 0.74;
	dots.alphaSpeed = 0.55;
    
    dots.contents = (id)[[UIImage imageNamed:@"spark"] CGImage];
    
    dots.velocityRange = 500;
    dots.emissionRange = 360;
    dots.scale = 0.5;
    dots.scaleRange = 0.2;
    dots.alphaRange = 0.3;
    dots.alphaSpeed  = 0.5;
    
    [dots setName:@"dots"];
    
    // add the cell to the layer and we're done
    dotsEmitter.emitterCells = [NSArray arrayWithObject:dots];
    
    return dotsEmitter;
}

#pragma mark - BuildEmitterStar
- (CAEmitterLayer*) buildEmitterStar:(CGSize)viewBounds
{
    CAEmitterLayer *starLayer = [self makeEmitterAtPoint:viewBounds];
    CAEmitterCell *starCell = [self makeEmitterCellWithParticle:@"star"];
    [starLayer setEmitterCells:@[starCell]];
    [starLayer setValue:@5 forKeyPath:@"emitterCells.star.birthRate"];
    
    return starLayer;
}

- (CAEmitterLayer *) makeEmitterAtPoint:(CGSize)viewBounds
{
    CAEmitterLayer *emitterLayer = [CAEmitterLayer layer];
	emitterLayer.name = @"starLayer";
	emitterLayer.emitterPosition = CGPointMake(30, 10);
	emitterLayer.emitterZPosition = -43;
	emitterLayer.emitterSize = CGSizeMake(viewBounds.width, 10);
	emitterLayer.emitterDepth = 0.00;
	emitterLayer.emitterShape = kCAEmitterLayerCircle;
	emitterLayer.emitterMode = kCAEmitterLayerSurface;
	emitterLayer.renderMode = kCAEmitterLayerBackToFront;
	emitterLayer.seed = 721963909;
    
    return emitterLayer;
}

- (CAEmitterCell *) makeEmitterCellWithParticle:(NSString *)name
{
	CAEmitterCell *emitterCell = [CAEmitterCell emitterCell];
	
	emitterCell.name = @"star";
	emitterCell.enabled = YES;
    
	emitterCell.contents = (id)[[UIImage imageNamed:name] CGImage];
	emitterCell.contentsRect = CGRectMake(0.00, 0.00, 1.00, 1.00);
    
	emitterCell.magnificationFilter = kCAFilterTrilinear;
	emitterCell.minificationFilter = kCAFilterLinear;
	emitterCell.minificationFilterBias = 0.00;
    
	emitterCell.scale = 0.72;
	emitterCell.scaleRange = 0.14;
	emitterCell.scaleSpeed = -0.25;
    
	emitterCell.color = [[UIColor colorWithRed:0.77 green:0.55 blue:0.60 alpha:0.55] CGColor];
	emitterCell.redRange = 0.9;
	emitterCell.greenRange = 0.8;
	emitterCell.blueRange = 0.7;
	emitterCell.alphaRange = 0.8;
    
	emitterCell.redSpeed = 0.92;
	emitterCell.greenSpeed = 0.84;
	emitterCell.blueSpeed = 0.74;
	emitterCell.alphaSpeed = 0.55;
    
	emitterCell.lifetime = 9.0;
	emitterCell.lifetimeRange = 2.37;
	emitterCell.birthRate = 0;
	emitterCell.velocity = -20.00;
	emitterCell.velocityRange = 2.00;
	emitterCell.xAcceleration = 1.00;
	emitterCell.yAcceleration = 10.00;
	emitterCell.zAcceleration = 12.00;
    
	// these values are in radians, in the UI they are in degrees
	emitterCell.spin = 0.384;
	emitterCell.spinRange = 0.925;
	emitterCell.emissionLatitude = 1.745;
	emitterCell.emissionLongitude = 1.745;
	emitterCell.emissionRange = 3.491;
    
    return emitterCell;
}

#pragma mark - BuildEmitterHeart
- (CAEmitterLayer*) buildEmitterHeart:(CGSize)viewBounds
{
    // Configure the particle emitter
	CAEmitterLayer	*heartsEmitter = [CAEmitterLayer layer];
	heartsEmitter.emitterPosition = CGPointMake(arc4random()%(int)viewBounds.width, arc4random()%(int)viewBounds.height);
	heartsEmitter.emitterSize = CGSizeMake(viewBounds.width * 2.0, 0.0);
	
	// Spawn points for the hearts are within the area defined by the button frame
	heartsEmitter.emitterMode = kCAEmitterLayerVolume;
	heartsEmitter.emitterShape = kCAEmitterLayerRectangle;
	heartsEmitter.renderMode = kCAEmitterLayerAdditive;
	
	// Configure the emitter cell
	CAEmitterCell *heart = [CAEmitterCell emitterCell];
	heart.name = @"heart";
	
	heart.emissionLongitude = M_PI/2.0; // up
	heart.emissionRange = 0.55 * M_PI;  // in a wide spread
	heart.birthRate		= 10;			// emitter is deactivated for now
	heart.lifetime		= 10.0;			// hearts vanish after 10 seconds
    
	heart.velocity		= -120;			// particles get fired up fast
	heart.velocityRange = 60;			// with some variation
	heart.yAcceleration = 20;			// but fall eventually
	
	heart.contents		= (id) [[UIImage imageNamed:@"DazHeart"] CGImage];
	heart.color			= [[UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:0.5] CGColor];
	heart.redRange		= 0.3;			// some variation in the color
	heart.blueRange		= 0.3;
	heart.alphaSpeed	= -0.5 / heart.lifetime;  // fade over the lifetime
	
	heart.scale			= 0.15;			// let them start small
	heart.scaleSpeed	= 0.5;			// but then 'explode' in size
	heart.spinRange		= 2.0 * M_PI;	// and send them spinning from -180 to +180 deg/s
	
	// Add everything to our backing layer
	heartsEmitter.emitterCells = [NSArray arrayWithObject:heart];
    
    CABasicAnimation *heartsBurst = [CABasicAnimation animationWithKeyPath:@"emitterCells.heart.birthRate"];
	heartsBurst.fromValue		= [NSNumber numberWithFloat:150.0];
	heartsBurst.toValue			= [NSNumber numberWithFloat:  0.0];
	heartsBurst.duration		= 5.0;
	heartsBurst.timingFunction	= [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	
	[heartsEmitter addAnimation:heartsBurst forKey:@"heartsBurst"];

	return heartsEmitter;
}

#pragma mark - BuildEmitterFireworks
- (CAEmitterLayer*) buildEmitterFireworks:(CGSize)viewBounds
{
    UIImage *image = [UIImage imageNamed:@"spark"];
	CAEmitterLayer *fireworksEmitter = [CAEmitterLayer layer];
    fireworksEmitter.emitterPosition = CGPointMake((arc4random()%(int)viewBounds.width*2/3)+30, (arc4random()%(int)viewBounds.height*2/3)+30);
	fireworksEmitter.renderMode = kCAEmitterLayerAdditive;
	
	// Invisible particle representing the rocket before the explosion
	CAEmitterCell *rocket = [CAEmitterCell emitterCell];
	rocket.emissionLongitude = (3 * M_PI) / 2;
	rocket.emissionLatitude = 0;
    rocket.birthRate = 1;
	rocket.lifetime = 1.6f;
	rocket.velocity = 150.0f;
	rocket.velocityRange = 150.0f;
	rocket.yAcceleration = -250;
	rocket.emissionRange = 8.0f * M_PI / 4;
	rocket.color = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5].CGColor;
	rocket.redRange = 0.5;
	rocket.greenRange = 0.5;
	rocket.blueRange = 0.5;
	
	// Name the cell so that it can be animated later using keypath
	[rocket setName:@"rocket"];
	
	// Flare particles emitted from the rocket as it flys
	CAEmitterCell *flare = [CAEmitterCell emitterCell];
	flare.contents = (id)image.CGImage;
	flare.emissionLongitude = (4 * M_PI) / 2;
	flare.scale = 0.4;
	flare.velocity = 100;
	flare.birthRate = 45;
	flare.lifetime = 1.5f;
	flare.yAcceleration = -350;
	flare.emissionRange = M_PI / 7;
	flare.alphaSpeed = -0.7;
	flare.scaleSpeed = -0.1;
	flare.scaleRange = 0.1;
	flare.beginTime = 0.01;
	flare.duration = 0.7;
	
	// The particles that make up the explosion
	CAEmitterCell *firework = [CAEmitterCell emitterCell];
	firework.contents = (id)image.CGImage;
	firework.birthRate = 9999;
	firework.scale = 0.6;
	firework.velocity = 150.0f;
    firework.velocityRange = 0.0f;
	firework.lifetime = 2;
	firework.alphaSpeed = -0.2;
	firework.yAcceleration = -80;
	firework.beginTime = 1.5;
	firework.duration = 0.1;
	firework.emissionRange = 2 * M_PI;
	firework.scaleSpeed = -0.1;
	firework.spin = 2;
	
	// Name the cell so that it can be animated later using keypath
	[firework setName:@"firework"];
	
	// preSpark is an invisible particle used to later emit the spark
	CAEmitterCell *preSpark = [CAEmitterCell emitterCell];
	preSpark.birthRate = 80;
	preSpark.velocity = firework.velocity * 0.70;
	preSpark.lifetime = 1.7;
	preSpark.yAcceleration = firework.yAcceleration * 0.85;
	preSpark.beginTime = firework.beginTime - 0.2;
	preSpark.emissionRange = firework.emissionRange;
	preSpark.greenSpeed = 100;
	preSpark.blueSpeed = 100;
	preSpark.redSpeed = 100;
	
	// Name the cell so that it can be animated later using keypath
	[preSpark setName:@"preSpark"];
	
	// The 'sparkle' at the end of a firework
	CAEmitterCell *spark = [CAEmitterCell emitterCell];
	spark.contents = (id)image.CGImage;
	spark.lifetime = 0.05;
	spark.yAcceleration = -250;
	spark.beginTime = 0.8;
	spark.scale = 0.4;
	spark.birthRate = 10;
    
	preSpark.emitterCells = [NSArray arrayWithObjects:spark, nil];
	rocket.emitterCells = [NSArray arrayWithObjects:flare, firework, preSpark, nil];
	fireworksEmitter.emitterCells = [NSArray arrayWithObjects:rocket, nil];
    
    fireworksEmitter.birthRate = 5;
	
    return fireworksEmitter;
}

#pragma mark - BuildEmitterSpark
- (CAEmitterLayer*) buildEmitterSpark:(CGSize)viewBounds
{
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    float defaultBirthRate = 10.0f;
    [cell setBirthRate:defaultBirthRate];
    [cell setVelocity:120];
    [cell setVelocityRange:40];
    [cell setYAcceleration:-45.0f];
    [cell setEmissionLongitude:-M_PI_2];
    [cell setEmissionRange:M_PI_4];
    [cell setScale:1.0f];
    [cell setScaleSpeed:2.0f];
    [cell setScaleRange:2.0f];
    cell.contents = (id) [[UIImage imageNamed:@"smoke15"] CGImage];
    [cell setColor:[UIColor colorWithRed:1.0 green:0.2 blue:0.1 alpha:0.5].CGColor];
    [cell setLifetime:1.0f];
    [cell setLifetimeRange:1.0f];
    
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    [emitter setEmitterCells:@[cell]];
    CGRect bounds = CGRectMake(0, 0, viewBounds.width/2, viewBounds.height);
    [emitter setFrame:bounds];
    CGPoint emitterPosition = CGPointMake(arc4random()%(int)viewBounds.width, arc4random()%(int)viewBounds.height);
    [emitter setEmitterPosition:emitterPosition];
    [emitter setEmitterSize:(CGSize){10.0f, 10.0f}];
    [emitter setEmitterShape:kCAEmitterLayerRectangle];
    [emitter setRenderMode:kCAEmitterLayerAdditive];
    emitter.geometryFlipped = YES;
    
    NSString *animationKey = @"position";
    CGFloat duration = 1.0f;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"emitterPosition"];
    CAEmitterLayer *presentation = (CAEmitterLayer*)[emitter presentationLayer];
    CGPoint currentPosition = [presentation emitterPosition];
    [animation setFromValue:[NSValue valueWithCGPoint:currentPosition]];
    [animation setToValue:[NSValue valueWithCGPoint:CGPointMake(arc4random()%(int)viewBounds.width/2, arc4random()%(int)viewBounds.height/2)]];
    [animation setDuration:duration];
    [animation setFillMode:kCAFillModeForwards];
    [animation setRemovedOnCompletion:NO];
    [emitter addAnimation:animation forKey:animationKey];
    
    return emitter;
}

#pragma mark - BuildEmitterFire
- (CAEmitterLayer*) buildEmitterFire:(CGSize)viewBounds position:(CGPoint)position
{
    // Create the emitter layers
	CAEmitterLayer *fireEmitter	= [CAEmitterLayer layer];
	// Place layers just above the tab bar
	fireEmitter.emitterPosition = position;
	fireEmitter.emitterSize	= CGSizeMake(viewBounds.width/2.0, 0);
	fireEmitter.emitterMode	= kCAEmitterLayerOutline;
	fireEmitter.emitterShape	= kCAEmitterLayerLine;
	// with additive rendering the dense cell distribution will create "hot" areas
	fireEmitter.renderMode		= kCAEmitterLayerAdditive;
	
	// Create the fire emitter cell
	CAEmitterCell* fire = [CAEmitterCell emitterCell];
	[fire setName:@"fire"];
    
	fire.birthRate			= 100;
	fire.emissionLongitude  = M_PI;
	fire.velocity			= -80;
	fire.velocityRange		= 30;
	fire.emissionRange		= 1;
	fire.yAcceleration		= 200;
	fire.scaleSpeed			= 0.2;
	fire.lifetime			= 50;
	fire.lifetimeRange		= (50.0 * 0.35);
    
	fire.color = [[UIColor colorWithRed:0.8 green:0.4 blue:0.2 alpha:0.1] CGColor];
	fire.contents = (id) [[UIImage imageNamed:@"DazFire"] CGImage];
    
	
	fireEmitter.emitterCells	= [NSArray arrayWithObject:fire];
	
    // Update the fire properties
    int value = 1.5;
	[fireEmitter setValue:[NSNumber numberWithInt:(value * 40)]
					forKeyPath:@"emitterCells.fire.birthRate"];
	[fireEmitter setValue:[NSNumber numberWithFloat:value]
					forKeyPath:@"emitterCells.fire.lifetime"];
	[fireEmitter setValue:[NSNumber numberWithFloat:(value * 0.35)]
					forKeyPath:@"emitterCells.fire.lifetimeRange"];
	fireEmitter.emitterSize = CGSizeMake(3 * value, 0);
	
    return fireEmitter;
}

- (CAEmitterLayer*) buildEmitterSmoke:(CGSize)viewBounds position:(CGPoint)position
{
    // Create the emitter layers
	CAEmitterLayer *smokeEmitter	= [CAEmitterLayer layer];
	smokeEmitter.emitterPosition = position;
	smokeEmitter.emitterMode	= kCAEmitterLayerPoints;
	
	// Create the smoke emitter cell
	CAEmitterCell* smoke = [CAEmitterCell emitterCell];
	[smoke setName:@"smoke"];
	smoke.birthRate			= 10;
	smoke.emissionLongitude = -M_PI / 2;
	smoke.lifetime			= 10;
	smoke.velocity			= -40;
	smoke.velocityRange		= 10;
	smoke.emissionRange		= M_PI / 4;
	smoke.spin				= 1;
	smoke.spinRange			= 6;
	smoke.yAcceleration		= 60;
	smoke.contents			= (id)[[UIImage imageNamed:@"DazSmoke"] CGImage];
	smoke.scale				= 0.1;
	smoke.alphaSpeed		= -0.12;
	smoke.scaleSpeed		= 0.7;
	
	// Add the smoke emitter cell to the smoke emitter layer
	smokeEmitter.emitterCells	= [NSArray arrayWithObject:smoke];
	
    // Update the fire properties
    int value = 1.5;
	[smokeEmitter setValue:[NSNumber numberWithInt:value * 4]
                forKeyPath:@"emitterCells.smoke.lifetime"];
	[smokeEmitter setValue:(id)[[UIColor colorWithRed:1 green:1 blue:1 alpha:value * 0.3] CGColor]
                forKeyPath:@"emitterCells.smoke.color"];
    
    return smokeEmitter;
}

#pragma mark - BuildEmitterSparkle
- (CAEmitterCell *)sparkCell
{
    CAEmitterCell *spark = [CAEmitterCell emitterCell];
    spark.contents = (__bridge id)[UIImage imageNamed:@"spark.png"].CGImage;
    spark.birthRate = 300;
    spark.lifetime = 3;
    spark.scale = 0.1;
    spark.scaleRange = 0.2;
    spark.emissionRange = 2 * M_PI;
    spark.velocity = 60;
    spark.velocityRange = 8;
    spark.yAcceleration = -200;
    spark.alphaRange = 0.5;
    spark.alphaSpeed = -1;
    spark.spin = 1;
    spark.spinRange = 6;
    spark.alphaRange = 0.8;
    spark.redRange = 2;
    spark.greenRange = 1;
    spark.blueRange = 1;
    [spark setName:kSparkCellKey];
    
    return spark;
}

- (CAEmitterCell *)smokeCell
{
    CAEmitterCell *smoke = [CAEmitterCell emitterCell];
    smoke.contents = (__bridge id)[UIImage imageNamed:@"smoke.png"].CGImage;
    smoke.birthRate = 5;
    smoke.lifetime = 20;
    smoke.scale = 0.1;
    smoke.scaleSpeed = 1;
    smoke.alphaRange = 0.5;
    smoke.alphaSpeed = -0.7;
    smoke.spin = 1;
    smoke.spinRange = 0.8;
    smoke.blueRange = 0.3;
    smoke.velocity = 10;
    smoke.yAcceleration = 100;
    [smoke setName:kSmokeCellKey];
    
    return smoke;
}

- (UIBezierPath*) createPathForText:(NSString*)string fontHeight:(CGFloat)height
{
    if ([string length] < 1)
        return nil;
    
    UIBezierPath *combinedGlyphsPath = nil;
    CGMutablePathRef letters = CGPathCreateMutable();
    
    CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica"), height, NULL);
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)font, kCTFontAttributeName,
                           nil];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string
                                                                     attributes:attrs];
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
	CFArrayRef runArray = CTLineGetGlyphRuns(line);
    
    // for each RUN
    for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++)
    {
        // Get FONT for this run
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        
        // for each GLYPH in run
        for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++)
        {
            // get Glyph & Glyph-data
            CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
            CGGlyph glyph;
            CGPoint position;
            CTRunGetGlyphs(run, thisGlyphRange, &glyph);
            CTRunGetPositions(run, thisGlyphRange, &position);
            
            // Get PATH of outline
            {
                CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
                CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
                CGPathAddPath(letters, &t, letter);
                CGPathRelease(letter);
            }
        }
    }
    CFRelease(line);
    
    combinedGlyphsPath = [UIBezierPath bezierPath];
    [combinedGlyphsPath moveToPoint:CGPointZero];
    [combinedGlyphsPath appendPath:[UIBezierPath bezierPathWithCGPath:letters]];
    
    CGPathRelease(letters);
    CFRelease(font);
    
    if (attrString)
    {
        [attrString release];
        attrString = nil;
    }
    
    return combinedGlyphsPath;
}

- (void)doAnimation:(CAShapeLayer *)textShapeLayer emitterLayer:(CAEmitterLayer *)emitterLayer startTime:(NSTimeInterval)timeInterval
{
    NSTimeInterval duration = 5;
    
    // Animate drawing of line
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @0.8;
    alphaAnimation.toValue = @1;
    alphaAnimation.duration = duration*2;
    alphaAnimation.beginTime = timeInterval;

    CABasicAnimation *stroke = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    stroke.duration = duration;
    stroke.fromValue = [NSNumber numberWithFloat:0.1];
    stroke.toValue = [NSNumber numberWithFloat:1];
    stroke.removedOnCompletion = NO;
    stroke.beginTime = timeInterval;
    
    [textShapeLayer addAnimation:alphaAnimation forKey:@"opacity"];
    [textShapeLayer addAnimation:stroke forKey:kStrokeAnimation];
    
    // Adjust the emitter
    emitterLayer.birthRate = 1;
    
    // Particle animation
    CAKeyframeAnimation *sparkle = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    sparkle.path = textShapeLayer.path;
    sparkle.fillMode = kCAAnimationPaced;
    sparkle.duration = duration;
    sparkle.removedOnCompletion = NO;
    sparkle.beginTime = timeInterval;
    [emitterLayer addAnimation:sparkle forKey:kEmitterAnimation];
    
    dispatch_async_main_after(duration, ^{
        emitterLayer.birthRate = 0;
    });
}

- (CAShapeLayer*) buildEmitterSparkle:(CGSize)viewBounds text:(NSString*)text startTime:(NSTimeInterval)timeInterval
{
    if ([text length] < 1)
        return nil;
    
    NSTimeInterval startTime = CMTimeGetSeconds(kCMTimeZero) + timeInterval;
    CGFloat height = viewBounds.height/10;
    CGPoint position = CGPointMake(viewBounds.width/2, height);
    UIBezierPath *path = [self createPathForText:text fontHeight:height];
    
    CAShapeLayer *textShapeLayer = [CAShapeLayer layer];
    textShapeLayer.path = path.CGPath;
    textShapeLayer.bounds = CGPathGetBoundingBox(path.CGPath);
    textShapeLayer.lineWidth = 1;
    textShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    textShapeLayer.fillColor = [[UIColor clearColor] CGColor];
    textShapeLayer.geometryFlipped = NO;
    textShapeLayer.position = position;
    textShapeLayer.opacity = 0;
    
    // Emitter layer
    CAEmitterLayer *emitterLayer = [CAEmitterLayer layer];
    emitterLayer.emitterCells = [NSArray arrayWithObjects:[self sparkCell], [self smokeCell], nil];
    emitterLayer.emitterShape = kCAEmitterLayerPoint;
    emitterLayer.birthRate = 0;
    emitterLayer.geometryFlipped = YES;
   
    [textShapeLayer addSublayer:emitterLayer];
    [self doAnimation:textShapeLayer emitterLayer:emitterLayer startTime:startTime];
    
    return textShapeLayer;
}

#pragma mark - BuildEmitterSteam
- (CAEmitterLayer*) buildEmitterSteam:(CGSize)viewBounds positon:(CGPoint)postion
{
    CAEmitterLayer *emitterLayer = [CAEmitterLayer layer];
    emitterLayer.emitterPosition = postion; 
    emitterLayer.emitterSize = CGSizeMake(viewBounds.width, 0);
    
    CAEmitterCell* cell = [CAEmitterCell emitterCell];
    cell.birthRate = 30;
    cell.lifetime = 3.0;
    cell.lifetimeRange = 2;
    cell.color = [[UIColor whiteColor] CGColor];
    cell.contents = (id)[[UIImage imageNamed:@"steam.png"] CGImage];
    [cell setName:@"steam"];
    
    emitterLayer.emitterCells = @[cell];
    
    cell.velocity = 30;
    cell.velocityRange = 10;
    cell.emissionRange = M_PI_4;
    cell.scaleSpeed = 0.2;
    cell.spin = 1;
    cell.spinRange = 3;
    
    emitterLayer.renderMode = kCAEmitterLayerAdditive;
    emitterLayer.emitterShape = kCAEmitterLayerLine;
    
    return emitterLayer;
}

#pragma mark - BuildEmitterSky
- (CAEmitterLayer*) buildEmitterSky:(CGSize)viewBounds
{
    // Build sky
    CAEmitterLayer *emitterLayer = [CAEmitterLayer layer];
    emitterLayer.emitterPosition = CGPointMake(viewBounds.width/2, viewBounds.height/2);
    emitterLayer.emitterSize = viewBounds;
    emitterLayer.renderMode = kCAEmitterLayerOldestLast;
    emitterLayer.emitterMode = kCAEmitterLayerSurface;
    emitterLayer.emitterShape = kCAEmitterLayerSphere;
    emitterLayer.seed = (arc4random()%100)+1;
    
    CAEmitterCell *cycleCell = [CAEmitterCell emitterCell];
    cycleCell.birthRate = 0.1;
    cycleCell.lifetime = 1;
    cycleCell.contents = (id)[[UIImage imageNamed:@"point"] CGImage];
    cycleCell.color = [[UIColor whiteColor] CGColor];
    cycleCell.velocity = 10;
    cycleCell.velocityRange = 2;
    cycleCell.alphaRange = 0.5;
    cycleCell.alphaSpeed = 2;
    cycleCell.scale = 0.1;
    cycleCell.scaleRange = 0.1;
    [cycleCell setName:@"starPoint"];
    
    CAEmitterCell *starCell = [CAEmitterCell emitterCell];
    starCell.birthRate = 3;
    starCell.lifetime = 2.02;
    
    CAEmitterCell *starCell0 = [CAEmitterCell emitterCell];
    starCell0.birthRate = 3;
    starCell0.lifetime = 1.02;
    starCell0.velocity = 0;
    starCell0.emissionRange = 2*M_PI;
    starCell0.contents = (id)[[UIImage imageNamed:@"bgStar"] CGImage];
    starCell0.color = [[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5] CGColor];
    starCell0.alphaSpeed = 0.6;
    starCell0.scale = 0.4;
    [starCell0 setName:@"star"];
    
    CAEmitterCell *starCell1 = [CAEmitterCell emitterCell];
    starCell1.birthRate = 3;
    starCell1.lifetime = 1.02;
    starCell1.velocity = 0;
    starCell1.emissionRange = 2*M_PI;
    
    CAEmitterCell *starCell2 = [CAEmitterCell emitterCell];
    starCell2.birthRate = 3;
    starCell2.lifetime = 1;
    starCell2.velocity = 0;
    starCell2.emissionRange = 2*M_PI;
    starCell2.contents = (id)[[UIImage imageNamed:@"bgStar1"] CGImage];
    starCell2.color = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5].CGColor;
    starCell2.alphaSpeed = -0.5;
    starCell2.scale = starCell0.scale;
    
    
    emitterLayer.emitterCells = @[starCell];
    starCell.emitterCells = @[starCell0, starCell1];
    starCell1.emitterCells = @[starCell2];

    return emitterLayer;
}

 // Build meteor
- (CAEmitterLayer*) buildEmitterMeteor:(CGSize)viewBounds startTime:(NSTimeInterval)timeInterval pathN:(NSInteger)pathN
{
    CAEmitterLayer *emitterLayer = [CAEmitterLayer layer];
    emitterLayer.emitterPosition = CGPointMake(160, 160);
    emitterLayer.emitterSize = viewBounds;
    emitterLayer.renderMode = kCAEmitterLayerAdditive;
    emitterLayer.emitterMode = kCAEmitterLayerPoints;
	emitterLayer.emitterShape = kCAEmitterLayerSphere;
    emitterLayer.opacity = 0;
    
    CAEmitterCell *cell1 = [self productEmitterCellWithContents:(id)[[UIImage imageNamed:@"star1"] CGImage]];
    cell1.scale = 0.3;
    cell1.scaleRange = 0.1;
    
    CAEmitterCell *cell2 = [self productEmitterCellWithContents:(id)[[UIImage imageNamed:@"cycle1"] CGImage]];
    cell2.scale = 0.05;
    cell2.scaleRange = 0.02;
    
    emitterLayer.emitterCells = @[cell1, cell2];
    
    NSTimeInterval duration = 5;
    CGMutablePathRef path = CGPathCreateMutable();
    CAKeyframeAnimation *animationPath = [CAKeyframeAnimation animationWithKeyPath:@"emitterPosition"];
    if (pathN < 1)
    {
        CGPathMoveToPoint(path, NULL, 0, 0);
        CGPathAddCurveToPoint(path, NULL, 50.0, 100.0, 50.0, 120.0, 50.0, 275.0);
        CGPathAddCurveToPoint(path, NULL, 50.0, 275.0, 150.0, 275.0, 160.0, 160.0);
        CGPathAddCurveToPoint(path, NULL, 160.0, 160.0, 160.0, 160.0, 160.0, 160.0);
    }
    else
    {
        CGPathMoveToPoint(path, NULL, 320 - 0, 320 - 0);
        CGPathAddCurveToPoint(path, NULL, 320 - 50.0, 320 - 100.0, 320 - 50.0, 320 - 120.0, 320 - 50.0, 320 - 275.0);
        CGPathAddCurveToPoint(path, NULL, 320 - 50.0, 320 - 275.0, 320 - 150.0, 320 - 275.0, 160.0, 160.0);
        CGPathAddCurveToPoint(path, NULL, 160.0, 160.0, 160.0, 160.0, 160.0, 160.0);
    }
    
    animationPath.path = path;
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = duration;
    opacityAnimation.values = @[@0.0, @0.5, @1];
    opacityAnimation.keyTimes = @[@0, @0.2, @1];
    opacityAnimation.removedOnCompletion = NO;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = duration;
    animationGroup.repeatCount = 1;
    animationGroup.removedOnCompletion = NO;
    animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animationGroup.beginTime = timeInterval;
    NSArray *animations = @[animationPath, opacityAnimation];
    animationGroup.animations = animations;
    [emitterLayer addAnimation:animationGroup forKey:nil];
   
    dispatch_async_main_after((duration+1), ^{
        emitterLayer.birthRate = 1;
        CGPathRelease(path);
    });
    
    return emitterLayer;
}

- (UIBezierPath *) pathForButton:(CGSize)viewBounds
{
    int numberOfEdges = 10;
    int inset = 1;
	CGPoint center = CGPointMake(viewBounds.width/2.0, viewBounds.height/2.0);
	CGFloat outerRadius = MIN(viewBounds.width, viewBounds.height) / 2.0 - inset;
	CGFloat innerRadius = outerRadius * 0.75;
	CGFloat angle = M_PI * 2.0 / (numberOfEdges * 2);
	UIBezierPath *path = [UIBezierPath bezierPath];
	for (NSInteger cc=0; cc<numberOfEdges; cc++)
    {
		CGPoint p0 = CGPointMake(center.x + outerRadius * cos(angle * (cc*2)), center.y + outerRadius * sin(angle * (cc*2)));
		CGPoint p1 = CGPointMake(center.x + innerRadius * cos(angle * (cc*2+1)), center.y + innerRadius * sin(angle * (cc*2+1)));
		
		if (cc==0)
        {
			[path moveToPoint: p0];
		}
		else
        {
			[path addLineToPoint: p0];
		}
		[path addLineToPoint: p1];
	}
    
	[path closePath];
	return path;
}

- (CAEmitterCell *)productEmitterCellWithContents:(id)contents
{
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.birthRate = 100;
    cell.lifetime = 1;
    cell.lifetimeRange = 0.5;
    cell.contents = contents;
    cell.color = [[UIColor whiteColor] CGColor];
    cell.velocity = 60;
    cell.emissionLongitude = M_PI*2;
    cell.emissionRange = M_PI*2;
    cell.velocityRange = 10;
    cell.spin = 10;
    
    return cell;
}

#pragma mark - BuildEmitterRain
- (CAEmitterLayer*) buildEmitterRain:(CGSize)viewBounds
{
    CAEmitterLayer *parentLayer = [CAEmitterLayer layer];
    parentLayer.emitterPosition = CGPointMake(viewBounds.width/2.0, viewBounds.height+10);
    parentLayer.emitterSize		= CGSizeMake(viewBounds.width * 2.0, 0);
    
    // Spawn points for the flakes are within on the outline of the line
    parentLayer.emitterMode		= kCAEmitterLayerOutline;
	parentLayer.emitterShape	= kCAEmitterLayerLine;
    
    parentLayer.shadowOpacity = 1.0;
	parentLayer.shadowRadius  = 0.0;
	parentLayer.shadowOffset  = CGSizeMake(0.0, 1.0);
	parentLayer.shadowColor   = [[UIColor whiteColor] CGColor];
    parentLayer.seed = (arc4random()%100)+1;
    
    UIImage *image = [UIImage imageNamed:@"rain"];
    CAEmitterCell * rainLayer = [self createRainLayer:image];
    
    parentLayer.emitterCells = @[rainLayer];
    
    return parentLayer;
}

-(CAEmitterCell *) createRainLayer:(UIImage *)image
{
    CAEmitterCell *cellLayer = [CAEmitterCell emitterCell];
    
    cellLayer.birthRate		= 100.0;
    cellLayer.lifetime		= 5;
	
	cellLayer.velocity		= 1000;				// falling down slowly
	cellLayer.velocityRange = 0;
    
    cellLayer.scale = 0.2;
    cellLayer.contents		= (id)[image CGImage];
    
    cellLayer.color			= [[UIColor grayColor] CGColor];
    cellLayer.emissionLongitude = 0.1 * M_PI;
    cellLayer.spin = 0.1 * M_PI;
    
    return cellLayer;
}

#pragma mark - BuildEmitterBirthday
- (CAEmitterLayer*) buildEmitterBirthday:(CGSize)viewBounds
{
    CAEmitterLayer *parentLayer = [CAEmitterLayer layer];
    parentLayer.emitterPosition = CGPointMake(viewBounds.width/2.0, viewBounds.height);
    parentLayer.emitterSize	= CGSizeMake(viewBounds.width * 2.0, 0);
    
    // Spawn points for the flakes are within on the outline of the line
    parentLayer.emitterMode	= kCAEmitterLayerOutline;
	parentLayer.emitterShape = kCAEmitterLayerLine;
    
    parentLayer.shadowOpacity = 1.0;
	parentLayer.shadowRadius  = 0.0;
	parentLayer.shadowOffset  = CGSizeMake(0.0, 1.0);
	parentLayer.shadowColor   = [[UIColor whiteColor] CGColor];
    parentLayer.seed = (arc4random()%100)+1;
    
    CAEmitterCell* containerLayer = [CAEmitterCell emitterCell];
	containerLayer.birthRate = 2;
	containerLayer.velocity	= -1;
	containerLayer.lifetime	= 0.5;
    containerLayer.name = @"containerLayer";
    
    UIImage *image = [UIImage imageNamed:@"birthday"];
    CAEmitterCell * birthdayLayer = [self createBirthdayLayer:image];
    
    containerLayer.emitterCells = @[birthdayLayer];
    parentLayer.emitterCells = @[containerLayer];
    
    return parentLayer;
}

-(CAEmitterCell *) createBirthdayLayer:(UIImage *)image
{
    CAEmitterCell *cellLayer = [CAEmitterCell emitterCell];
    
    cellLayer.birthRate	= 3.0;
    cellLayer.lifetime  = 20;
	
	cellLayer.velocity	= -100;				// falling down slowly
	cellLayer.velocityRange = 0;
	cellLayer.yAcceleration = 2;
    cellLayer.emissionRange = 0.5 * M_PI;		// some variation in angle
    cellLayer.scale = 1.3;
    cellLayer.contents	= (id)[image CGImage];
    
    cellLayer.color	= [[UIColor whiteColor] CGColor];
    
    return cellLayer;
}

#pragma mark - BuildEmitterFlower
- (CAEmitterLayer*) buildEmitterFlower:(CGSize)viewBounds
{
    CAEmitterLayer *parentLayer = [CAEmitterLayer layer];
    parentLayer.emitterPosition = CGPointMake(viewBounds.width/2.0, viewBounds.height-10);
    parentLayer.emitterSize		= CGSizeMake(viewBounds.width * 2.0, 0);
    
    // Spawn points for the flakes are within on the outline of the line
    parentLayer.emitterMode		= kCAEmitterLayerOutline;
	parentLayer.emitterShape	= kCAEmitterLayerLine;
    
    parentLayer.shadowOpacity = 1.0;
	parentLayer.shadowRadius  = 0.0;
	parentLayer.shadowOffset  = CGSizeMake(0.0, 1.0);
	parentLayer.shadowColor   = [[UIColor whiteColor] CGColor];
    parentLayer.seed = (arc4random()%100)+1;
    
    CAEmitterCell* containerLayer = [CAEmitterCell emitterCell];
	containerLayer.birthRate = 1.0;
	containerLayer.velocity	= -1;
	containerLayer.lifetime	= 0.5;
    containerLayer.name = @"containerLayer";
    
    NSMutableArray *flowerArray = [NSMutableArray array];
    for (int i = 1; i <= 8; i++)
    {
        NSString *imageName = [NSString stringWithFormat:@"flower%i",i];
        UIImage *image = [UIImage imageNamed:imageName];
        if (image)
        {
            [flowerArray addObject:[self createFlowerLayer:image]];
        }
    }
    
    containerLayer.emitterCells = @[flowerArray[0], flowerArray[1], flowerArray[3], flowerArray[4], flowerArray[5], flowerArray[6], flowerArray[7]];
    parentLayer.emitterCells = @[containerLayer];

    return parentLayer;
}

-(CAEmitterCell *) createFlowerLayer:(UIImage *)image
{
    CAEmitterCell *cellLayer = [CAEmitterCell emitterCell];
    cellLayer.birthRate	= 3;
    cellLayer.lifetime	= 10;
	
	cellLayer.velocity	= -100;				// falling down slowly
	cellLayer.velocityRange = 20;
	cellLayer.yAcceleration = 2;
    cellLayer.emissionRange = 0.5 * M_PI;	// some variation in angle
    cellLayer.spinRange	= 0.5 * M_PI;		// slow spin
    cellLayer.scale = 0.2;
    cellLayer.scaleRange = 0.1;
    cellLayer.contents	= (id)[image CGImage];
    
    cellLayer.color	= [[UIColor whiteColor] CGColor];
    cellLayer.redRange = 1.0;
    cellLayer.greenRange = 1.0;
    cellLayer.blueRange = 1.0;
    
    return cellLayer;
}

#pragma mark - buildAnimatedStarText
- (CALayer *)buildAnimationStarText:(CGSize)viewBounds text:(NSString*)text;
{
    if (!text || [text isEqualToString:@""])
    {
        return nil;
    }
    
	// Create a layer for the overall title animation.
	CALayer *animatedTitleLayer = [CALayer layer];
	
	// 1. Create a layer for the text of the title.
    CGFloat fontHeight = viewBounds.height/20;
	CATextLayer *titleLayer = [CATextLayer layer];
	titleLayer.string = text;
	titleLayer.font = (__bridge CFTypeRef)(@"Helvetica");
	titleLayer.fontSize = fontHeight;
	titleLayer.alignmentMode = kCAAlignmentCenter;
	titleLayer.bounds = CGRectMake(0, 0, viewBounds.width, fontHeight+10);
	
//    [titleLayer addAnimation:[self animationRotationZ:3.0 durationTimes:3.0] forKey:@"rotationOut"];
    
	// Add it to the overall layer.
	[animatedTitleLayer addSublayer:titleLayer];
	
    
	// 2. Create a layer that contains a ring of stars.
	CALayer *ringOfStarsLayer = [CALayer layer];
    
	NSInteger starCount = 9, star;
	CGFloat starRadius = viewBounds.height / 15;
	CGFloat ringRadius = viewBounds.height * 0.5 / 2;
	CGImageRef starImage = createStarImage(starRadius);
	for (star = 0; star < starCount; star++)
    {
		CALayer *starLayer = [CALayer layer];
		CGFloat angle = star * 2 * M_PI / starCount;
		starLayer.bounds = CGRectMake(0, 0, 2 * starRadius, 2 * starRadius);
		starLayer.position = CGPointMake(ringRadius * cos(angle), ringRadius * sin(angle));
		starLayer.contents = (__bridge id)starImage;
		[ringOfStarsLayer addSublayer:starLayer];
	}
	CGImageRelease(starImage);
	
	// Rotate the ring of stars.
	CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
	rotationAnimation.repeatCount = 1e100; // forever
	rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0];
	rotationAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI];
	rotationAnimation.duration = 3.0; // repeat every 3 seconds
	rotationAnimation.additive = YES;
	rotationAnimation.removedOnCompletion = NO;
	rotationAnimation.beginTime = 1e-100; // CoreAnimation automatically replaces zero beginTime with CACurrentMediaTime().  The constant AVCoreAnimationBeginTimeAtZero is also available.
	[ringOfStarsLayer addAnimation:rotationAnimation forKey:nil];
	
	// Add the ring of stars to the overall layer.
	animatedTitleLayer.position = CGPointMake(viewBounds.width / 2.0, viewBounds.height / 2.0);
	[animatedTitleLayer addSublayer:ringOfStarsLayer];
	
    // 3.
    CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeInAnimation.fromValue = @0.0f;
	fadeInAnimation.toValue = @1.0f;
	fadeInAnimation.additive = NO;
	fadeInAnimation.removedOnCompletion = NO;
	fadeInAnimation.beginTime = 1.0;
	fadeInAnimation.duration = 2.0;
	fadeInAnimation.autoreverses = NO;
	fadeInAnimation.fillMode = kCAFillModeBoth;
    
	CMTime animatedOutStartTime = CMTimeAdd(kCMTimeZero, CMTimeMake(3, 1));

    CABasicAnimation* rotationAnimationLayer = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimationLayer.toValue = @((2 * M_PI) * -2); // 3 is the number of 360 degree rotations
    // Make the rotation animation duration slightly less than the other animations to give it the feel
    // that it pauses at its largest scale value
    rotationAnimationLayer.duration = 3.0f;
    rotationAnimationLayer.beginTime = CMTimeGetSeconds(animatedOutStartTime);
    rotationAnimationLayer.removedOnCompletion = NO;
    rotationAnimationLayer.autoreverses = NO;
    rotationAnimationLayer.fillMode = kCAFillModeForwards;
    rotationAnimationLayer.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = @1.0f;
    scaleAnimation.toValue = @0.0f;
    scaleAnimation.duration = 1.0f;
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.autoreverses = NO;
    scaleAnimation.beginTime = CMTimeGetSeconds(animatedOutStartTime);
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [animatedTitleLayer addAnimation:fadeInAnimation forKey:nil];
    [animatedTitleLayer addAnimation:rotationAnimationLayer forKey:@"spinOut"];
    [animatedTitleLayer addAnimation:scaleAnimation forKey:@"scaleOut"];
	
	return animatedTitleLayer;
}

#pragma mark - BuildAnimationScrollLine
- (CALayer*) buildAnimatedScrollLine:(CGSize)viewBounds startTime:(CFTimeInterval)timeInterval lineHeight:(CGFloat)lineHeight image:(UIImage*)image
{
    CGFloat width = viewBounds.width;
    CGFloat height = viewBounds.height;
    
    CALayer *lineLayer = [CALayer layer];
    lineLayer.backgroundColor = [UIColor clearColor].CGColor;
    UIImage *maskImage = [self maskImageForImage:width height:lineHeight];
    lineLayer.contents = (id) maskImage.CGImage;
    lineLayer.contentsGravity = kCAGravityCenter;
    lineLayer.frame = CGRectMake(0, -height, width, height*1.25);
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position.y"];
    anim.byValue = @(height * 2);
    anim.repeatCount = 5;
    anim.duration = 3.0f;
    anim.beginTime = CMTimeGetSeconds(kCMTimeZero) + timeInterval;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    [lineLayer addAnimation:anim forKey:@"shine"];
    
    if (image)
    {
        CALayer *shineLayer = [CALayer layer];
        UIImage *shineImage = [self highlightedImageForImage:image];
        shineLayer.contents = (id) shineImage.CGImage;
        shineLayer.frame = CGRectMake(0, 0, width, height);

        shineLayer.mask = lineLayer;
        
        return shineLayer;
    }
    else
    {
        return lineLayer;
    }
}

- (UIImage *)imageFromLayer:(CALayer *)layer
{
    UIGraphicsBeginImageContext([layer frame].size);
    
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (UIImage *)highlightedImageForImage:(UIImage *)image
{
    CIImage *coreImage = [CIImage imageWithCGImage:image.CGImage];
    CIImage *output = [CIFilter filterWithName:@"CIColorControls"
                                 keysAndValues:kCIInputImageKey, coreImage,
                       @"inputBrightness", @1.0f,
                       nil].outputImage;
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:output fromRect:output.extent];
    UIImage *newImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return newImage;
}

- (UIImage *)maskImageForImage:(CGFloat)width height:(CGFloat)maskHeight
{
    CGFloat maskWidth = floorf(width);
    
    UIGraphicsBeginImageContext(CGSizeMake(maskWidth, maskHeight));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    id clearColor = (__bridge id) [UIColor clearColor].CGColor;
    id blackColor = (__bridge id) [UIColor blackColor].CGColor;
    CGFloat locations[] = { 0.0f, 0.5f, 1.0f };
    NSArray *colors = @[ clearColor, blackColor, clearColor ];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        (__bridge CFArrayRef)colors,
                                                        locations);
    CGFloat midX = floorf(maskWidth/2);
    CGPoint startPoint = CGPointMake(midX, 0);
    CGPoint endPoint = CGPointMake(midX, (floorf(maskHeight/2)));
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CFRelease(gradient);
    CFRelease(colorSpace);
    
    UIImage *maskImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return maskImage;
}

#pragma mark - BuildAnimationGradientText
- (CALayer*) buildAnimatedScrollText:(CGSize)viewBounds text:(NSString*)text startPoint:(CGPoint)startPoint startTime:(NSTimeInterval)timeInterval
{
    CATextLayer *textLayer = [CATextLayer layer];
	textLayer.string = text;
	textLayer.font = (__bridge CFTypeRef)(@"Helvetica");
	textLayer.fontSize = 28;
	textLayer.alignmentMode = kCAAlignmentCenter;
	textLayer.bounds = CGRectMake(0, 0, viewBounds.width, viewBounds.height/10);
    
    CGPoint startPointIn = startPoint;
    CGPoint middlePoint = CGPointMake(viewBounds.width/2, startPoint.y);
    CGPoint endPointIn = CGPointMake(-viewBounds.width/2, startPoint.y);
    textLayer.position = endPointIn;
    
    CMTime animatedOutStartTime = CMTimeMake(1, 100);
    
    // 1.
    CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeInAnimation.fromValue = @0.0f;
	fadeInAnimation.toValue = @0.8f;
	fadeInAnimation.additive = NO;
	fadeInAnimation.removedOnCompletion = NO;
	fadeInAnimation.beginTime = CMTimeGetSeconds(animatedOutStartTime) + timeInterval;
	fadeInAnimation.duration = 3.0;
	fadeInAnimation.autoreverses = NO;
	fadeInAnimation.fillMode = kCAFillModeBoth;
    
    CABasicAnimation *moveInAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    [moveInAnimation setFromValue:[NSValue valueWithCGPoint:startPointIn]];
    [moveInAnimation setToValue:[NSValue valueWithCGPoint:middlePoint]];
    [moveInAnimation setDuration:2.0];
    moveInAnimation.beginTime = CMTimeGetSeconds(animatedOutStartTime) + timeInterval;
    moveInAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CAKeyframeAnimation *scaleInAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scaleInAnimation.duration = 3.0;
    scaleInAnimation.beginTime = CMTimeGetSeconds(animatedOutStartTime) + timeInterval;
    scaleInAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:.5f],
                    [NSNumber numberWithFloat:1.2f],
                    [NSNumber numberWithFloat:.85f],
                    [NSNumber numberWithFloat:1.f],
                    nil];
    
    // 2.
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeOutAnimation.fromValue = @1.0f;
	fadeOutAnimation.toValue = @0.0f;
	fadeOutAnimation.additive = NO;
	fadeOutAnimation.removedOnCompletion = NO;
	fadeOutAnimation.beginTime = CMTimeGetSeconds(animatedOutStartTime) + 2 + timeInterval ;
	fadeOutAnimation.duration = 3.0;
	fadeOutAnimation.autoreverses = NO;
	fadeOutAnimation.fillMode = kCAFillModeBoth;
    
    CABasicAnimation *moveOutAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    [moveOutAnimation setFromValue:[NSValue valueWithCGPoint:middlePoint]];
    [moveOutAnimation setToValue:[NSValue valueWithCGPoint:endPointIn]];
    [moveOutAnimation setDuration:2.0];
    moveOutAnimation.beginTime = CMTimeGetSeconds(animatedOutStartTime) + 2 + timeInterval;
    moveOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    CABasicAnimation* rotateOutAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateOutAnimation.toValue = @((2 * M_PI) * 2);
    rotateOutAnimation.duration = 2.0f;
    rotateOutAnimation.beginTime = CMTimeGetSeconds(animatedOutStartTime) + 2 + timeInterval;
    rotateOutAnimation.removedOnCompletion = NO;
    rotateOutAnimation.autoreverses = NO;
    rotateOutAnimation.fillMode = kCAFillModeForwards;
    rotateOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation *scaleOutAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleOutAnimation.fromValue = @1.0f;
    scaleOutAnimation.toValue = @0.0f;
    scaleOutAnimation.duration = 3.0f;
    scaleOutAnimation.removedOnCompletion = NO;
    scaleOutAnimation.fillMode = kCAFillModeForwards;
    scaleOutAnimation.autoreverses = NO;
    scaleOutAnimation.beginTime = CMTimeGetSeconds(animatedOutStartTime) + 2 + timeInterval;
    scaleOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [textLayer addAnimation:fadeInAnimation forKey:@"fadeIn"];
    [textLayer addAnimation:moveInAnimation forKey:@"positionIn"];
    [textLayer addAnimation:scaleInAnimation forKey:@"scaleIn"];
    [textLayer addAnimation:moveOutAnimation forKey:@"positionOut"];
    [textLayer addAnimation:fadeOutAnimation forKey:@"fadeOut"];
    [textLayer addAnimation:rotateOutAnimation forKey:@"spinOut"];
    [textLayer addAnimation:scaleOutAnimation forKey:@"scaleOut"];
    
    return textLayer;
}

#pragma mark - BuildAnimationScrollScreen
- (CALayer*) buildAnimationScrollScreen:(CGSize)viewBounds
{
    CALayer *animatedScrollLayer = [CALayer layer];
	
	// 1.
	CALayer *scrollUpLayer = [CALayer layer];
    scrollUpLayer.backgroundColor = [[UIColor blackColor] CGColor];
	scrollUpLayer.frame = CGRectMake(0, 0, viewBounds.width, viewBounds.height/2);
    
    CMTime animatedOutStartTime = CMTimeMake(1, 1000);
    CGPoint startPointUp = CGPointMake(viewBounds.width/2, viewBounds.height*3/4);
    CGPoint endPointUp = CGPointMake(viewBounds.width/2, viewBounds.height+viewBounds.height/2);
    
    CABasicAnimation *animationMoveUp = [CABasicAnimation animationWithKeyPath:@"position"];
    [animationMoveUp setFromValue:[NSValue valueWithCGPoint:startPointUp]];
    [animationMoveUp setToValue:[NSValue valueWithCGPoint:endPointUp]];
    [animationMoveUp setDuration:3.0];
    animationMoveUp.beginTime = CMTimeGetSeconds(animatedOutStartTime);
    
    [scrollUpLayer setPosition:endPointUp];
    [scrollUpLayer addAnimation:animationMoveUp forKey:@"positionUp"];
    
	// Add it to the overall layer.
	[animatedScrollLayer addSublayer:scrollUpLayer];
	
    
	// 2.
	CALayer *scrollDownLayer = [CALayer layer];
    scrollDownLayer.backgroundColor = [[UIColor blackColor] CGColor];
	scrollDownLayer.frame = CGRectMake(0, 0, viewBounds.width, viewBounds.height/2);
  	
    CGPoint startPointDown = CGPointMake(viewBounds.width/2, viewBounds.height*1/4);
    CGPoint endPointDown = CGPointMake(viewBounds.width/2, -viewBounds.height/2);
    
    CABasicAnimation *animationMoveDown = [CABasicAnimation animationWithKeyPath:@"position"];
    [animationMoveDown setFromValue:[NSValue valueWithCGPoint:startPointDown]];
    [animationMoveDown setToValue:[NSValue valueWithCGPoint:endPointDown]];
    [animationMoveDown setDuration:3.0];
    animationMoveDown.beginTime = CMTimeGetSeconds(animatedOutStartTime);
    
    [scrollDownLayer setPosition:endPointDown];
    [scrollDownLayer addAnimation:animationMoveDown forKey:@"positionDown"];
    
    // Add it to the overall layer.
	[animatedScrollLayer addSublayer:scrollDownLayer];
	
	return animatedScrollLayer;
}

#pragma mark - BuildAnimationFlashScreen
- (CALayer*) buildAnimationFlashScreen:(CGSize)viewBounds startTime:(NSTimeInterval)timeInterval startOpacity:(BOOL)startOpacity
{
    CALayer *animatedFlashLayer = [CALayer layer];
    animatedFlashLayer.bounds = CGRectMake(0, 0, viewBounds.width, viewBounds.height);
    animatedFlashLayer.position = CGPointMake(viewBounds.width/2, viewBounds.height/2);
    if (arc4random()%(int)2)
    {
        animatedFlashLayer.backgroundColor = [[UIColor whiteColor] CGColor];
    }
    else
    {
         animatedFlashLayer.backgroundColor = [[UIColor blackColor] CGColor];
    }
    
    animatedFlashLayer.opacity = 0;
    
    id startValue = nil;
    id endValue = nil;
	if (startOpacity)
    {
        startValue = @1.0f;
        endValue = @0.0f;
    }
    else
    {
        startValue = @0.0f;
        endValue = @1.0f;
    }
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = startValue;
    alphaAnimation.toValue = endValue;
    alphaAnimation.duration = 0.1f;
    alphaAnimation.beginTime = timeInterval;
    
    [animatedFlashLayer addAnimation:alphaAnimation forKey:@"opacity"];
    
    return animatedFlashLayer;
}

#pragma mark - BuildAnimationRipple
- (CALayer*) buildAnimationRipple:(CGSize)viewBounds centerPoint:(CGPoint)centerPoint radius:(CGFloat)radius startTime:(NSTimeInterval)startTime
{
    NSArray *colors = @[
                             [UIColor colorWithRed:0.000 green:0.478 blue:1.000 alpha:1],
                             [UIColor colorWithRed:240/255.f green:159/255.f blue:254/255.f alpha:1],
                             [UIColor colorWithRed:204/255.f green:270/255.f blue:12/255.f alpha:1],
                             [UIColor colorWithRed:240/255.f green:159/255.f blue:10/255.f alpha:1],
                             [UIColor colorWithRed:240/255.f green:159/255.f blue:254/255.f alpha:1],
                             [UIColor colorWithRed:255/255.f green:137/255.f blue:167/255.f alpha:1],
                             [UIColor colorWithRed:126/255.f green:242/255.f blue:195/255.f alpha:1],
                             [UIColor colorWithRed:119/255.f green:152/255.f blue:255/255.f alpha:1],
                             [UIColor colorWithRed:240/255.f green:159/255.f blue:254/255.f alpha:1],
                             [UIColor colorWithRed:255/255.f green:137/255.f blue:167/255.f alpha:1],
                             [UIColor colorWithRed:126/255.f green:242/255.f blue:195/255.f alpha:1],
                             [UIColor colorWithRed:119/255.f green:152/255.f blue:255/255.f alpha:1],
                             [UIColor colorWithRed:240/255.f green:159/255.f blue:254/255.f alpha:1],
                             [UIColor colorWithRed:255/255.f green:137/255.f blue:167/255.f alpha:1],
                             [UIColor colorWithRed:126/255.f green:242/255.f blue:195/255.f alpha:1],
                             [UIColor colorWithRed:119/255.f green:152/255.f blue:255/255.f alpha:1],
                             [UIColor colorWithWhite:0.8 alpha:0.8],
                         ];
    
    UIColor *stroke = colors[arc4random()%(int)[colors count]];
    NSTimeInterval animationDuration = 3; // default:3s
    NSTimeInterval pulseInterval = 0;
    CGFloat diameter = radius * 2;

    CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.cornerRadius = radius;
    circleShape.bounds = CGRectMake(0, 0, diameter, diameter);
    circleShape.position = centerPoint;
    circleShape.backgroundColor = stroke.CGColor;
    circleShape.strokeColor = [UIColor colorWithWhite:0.8 alpha:0.8].CGColor;
    circleShape.lineWidth = 3;
    circleShape.opacity = 0;
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
    scaleAnimation.fromValue = @0.0;
    scaleAnimation.toValue = @1.0;
    scaleAnimation.duration = animationDuration;
    
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = animationDuration;
    opacityAnimation.values = @[@0.45, @0.45, @0];
    opacityAnimation.keyTimes = @[@0, @0.2, @1];
    opacityAnimation.removedOnCompletion = NO;
    
    CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = animationDuration + pulseInterval;
    animationGroup.repeatCount = 1; // INFINITY;
    animationGroup.removedOnCompletion = NO;
    animationGroup.timingFunction = defaultCurve;
    animationGroup.beginTime = startTime;
    NSArray *animations = @[scaleAnimation, opacityAnimation];
    animationGroup.animations = animations;
    [circleShape addAnimation:animationGroup forKey:nil];
    
    return circleShape;
}

#pragma mark - BuildAnimationGradientScroll
- (CALayer*) buildGradientText:(CGSize)viewBounds positon:(CGPoint)postion text:(NSString*)text
{
    CGFloat height = viewBounds.height/10;
    UIBezierPath *path = [self createPathForText:text fontHeight:height];
    CGRect rectPath = CGPathGetBoundingBox(path.CGPath);
    CAShapeLayer *textLayer = [CAShapeLayer layer];
    textLayer.path = path.CGPath;
    textLayer.lineWidth = 1;
    textLayer.strokeColor = [UIColor lightGrayColor].CGColor;
    textLayer.fillColor = [[UIColor clearColor] CGColor];
    textLayer.geometryFlipped = NO;
    textLayer.opacity = 0;
    
    NSTimeInterval duration = 5;
    NSTimeInterval timeInterval = 1;
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @0.8;
    alphaAnimation.toValue = @1;
    alphaAnimation.duration = duration*1.2;
    alphaAnimation.beginTime = timeInterval;
    
    CABasicAnimation *stroke = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    stroke.duration = duration;
    stroke.fromValue = [NSNumber numberWithFloat:0.1];
    stroke.toValue = [NSNumber numberWithFloat:1];
    stroke.removedOnCompletion = NO;
    stroke.beginTime = timeInterval;
    
    [textLayer addAnimation:stroke forKey:@"stroke"];
    [textLayer addAnimation:alphaAnimation forKey:@"opacity"];
    
    CAGradientLayer *gradientLayer = [self performEffectAnimation:arc4random()%(int)8];
    [gradientLayer addSublayer:textLayer];
    [gradientLayer setMask:textLayer];
    gradientLayer.position = postion;
    gradientLayer.bounds = rectPath;
    
    CABasicAnimation *positionAnimationOut = [CABasicAnimation animationWithKeyPath:@"position"];
	positionAnimationOut.fromValue = [NSValue valueWithCGPoint:gradientLayer.position];
	positionAnimationOut.toValue = [NSValue valueWithCGPoint:CGPointZero];
    
	CABasicAnimation *boundsAnimationOut = [CABasicAnimation animationWithKeyPath:@"bounds"];
	boundsAnimationOut.fromValue = [NSValue valueWithCGRect:gradientLayer.bounds];
	boundsAnimationOut.toValue = [NSValue valueWithCGRect:CGRectZero];
    
	CABasicAnimation *opacityAnimationOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacityAnimationOut.fromValue = [NSNumber numberWithFloat:1.0];
	opacityAnimationOut.toValue = [NSNumber numberWithFloat:0.0];
	
	CABasicAnimation *rotateAnimationOut = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	rotateAnimationOut.fromValue = [NSNumber numberWithFloat:0 * M_PI];
	rotateAnimationOut.toValue = [NSNumber numberWithFloat:2 * M_PI];
	
	CAAnimationGroup *groupOut = [CAAnimationGroup animation];
	groupOut.beginTime = stroke.beginTime + stroke.duration;
	groupOut.duration = 1;
	groupOut.animations = [NSArray arrayWithObjects:positionAnimationOut, boundsAnimationOut, rotateAnimationOut, opacityAnimationOut, nil];
	groupOut.fillMode = kCAFillModeForwards;
	groupOut.removedOnCompletion = NO;
	
	[gradientLayer addAnimation:groupOut forKey:@"moveOut"];
    
    return gradientLayer;
}

- (CAGradientLayer*) performEffectAnimation:(EffectDirection)effectDirection
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = [self colorsForStage:0];
    
    switch (effectDirection)
    {
        case EffectDirectionLeftToRight:
        {
            gradientLayer.startPoint = CGPointMake(0.0, 0.5);
            gradientLayer.endPoint = CGPointMake(1.0, 0.5);
            
            break;
        }
        case EffectDirectionRightToLeft:
        {
            gradientLayer.startPoint = CGPointMake(1.0, 0.5);
            gradientLayer.endPoint = CGPointMake(0.0, 0.5);
            
            break;
        }
        case EffectDirectionTopToBottom:
        {
            gradientLayer.startPoint = CGPointMake(0.5, 0.0);
            gradientLayer.endPoint = CGPointMake(0.5, 1.0);
            
            break;
        }
        case EffectDirectionBottomToTop:
        {
            gradientLayer.startPoint = CGPointMake(0.5, 1.0);
            gradientLayer.endPoint = CGPointMake(0.5, 0.0);
            
            break;
        }
        case EffectDirectionBottomLeftToTopRight:
        {
            gradientLayer.startPoint = CGPointMake(0.0, 1.0);
            gradientLayer.endPoint = CGPointMake(1.0, 0.0);
            
            break;
        }
        case EffectDirectionBottomRightToTopLeft:
        {
            gradientLayer.startPoint = CGPointMake(1.0, 1.0);
            gradientLayer.endPoint = CGPointMake(0.0, 0.0);
            
            break;
        }
        case EffectDirectionTopLeftToBottomRight:
        {
            gradientLayer.startPoint = CGPointMake(0.0, 0.0);
            gradientLayer.endPoint = CGPointMake(1.0, 1.0);
            
            break;
        }
        case EffectDirectionTopRightToBottomLeft:
        {
            gradientLayer.startPoint = CGPointMake(1.0, 0.0);
            gradientLayer.endPoint = CGPointMake(0.0, 1.0);
            
            break;
        }
    }
    
    CABasicAnimation *animation0 = [self animationForStage:0];
    CABasicAnimation *animation1 = [self animationForStage:1];
    CABasicAnimation *animation2 = [self animationForStage:2];
    CABasicAnimation *animation3 = [self animationForStage:3];
    CABasicAnimation *animation4 = [self animationForStage:4];
    CABasicAnimation *animation5 = [self animationForStage:5];
    CABasicAnimation *animation6 = [self animationForStage:6];
    CABasicAnimation *animation7 = [self animationForStage:7];
    CABasicAnimation *animation8 = [self animationForStage:8];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = animation8.beginTime + animation8.duration;
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    group.repeatCount = 10;
    group.beginTime = 1.0;
    [group setAnimations:@[animation0, animation1, animation2, animation3, animation4, animation5, animation6, animation7, animation8]];
    
    [gradientLayer addAnimation:group forKey:@"animationOpacity"];
    
    return gradientLayer;
}

- (CABasicAnimation *) animationForStage:(NSUInteger)stage
{
    CGFloat duration = 0.3;
    CGFloat inset = 0.1;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    animation.fromValue = [self colorsForStage:stage];
    animation.toValue = [self colorsForStage:stage + 1];
    animation.beginTime = stage * (duration - inset);
    animation.duration = duration;
    animation.repeatCount = 1;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    return animation;
}

- (NSArray *) colorsForStage:(NSUInteger)stage
{
    UIColor *textColor = [UIColor whiteColor];
    UIColor *effectColor = [UIColor blackColor];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:8];
    
    for (int i = 0; i < 9; i++)
    {
        [array addObject:stage != 0 && stage == i ? (id)[effectColor CGColor] : (id)[textColor CGColor]];
    }
    
    return [NSArray arrayWithArray:array];
}

#pragma mark - BuildImage
- (CALayer*) buildImage:(CGSize)viewBounds image:(NSString*)imageFile position:(CGPoint)position
{
    if (!imageFile || [imageFile isEqualToString:@""])
    {
        return nil;
    }
    
    CALayer *layerImage = [CALayer layer];
    UIImage *image = [UIImage imageNamed:imageFile];
    layerImage.contents = (id)image.CGImage;
    layerImage.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    layerImage.opacity = 0.9;
    layerImage.position = position;
    
    return layerImage;
}

#pragma mark - BuildAnimationImages
- (CALayer*) buildAnimationImages:(CGSize)viewBounds imagesArray:(NSMutableArray *)imagesArray position:(CGPoint)position
{
    if ([imagesArray count] < 1)
    {
        return nil;
    }
    
    // Contains CMTime array for the time duration [0-1]
    NSMutableArray *keyTimesArray = [[NSMutableArray alloc] init];
    double currentTime = CMTimeGetSeconds(kCMTimeZero);
    NSLog(@"currentDuration %f",currentTime);
    
    for (int seed = 0; seed < [imagesArray count]; seed++)
    {
        NSNumber *tempTime = [NSNumber numberWithFloat:(currentTime + (float)seed/[imagesArray count])];
        [keyTimesArray addObject:tempTime];
    }
    
    NSLog(@"Key Times %@",keyTimesArray);
    UIImage *image = [UIImage imageWithCGImage:(CGImageRef)imagesArray[0]];
    
    AVSynchronizedLayer *animationLayer = [CALayer layer];
    animationLayer.opacity = 0.8;
    animationLayer.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    animationLayer.position = position;
    
    CAKeyframeAnimation *frameAnimation = [[CAKeyframeAnimation alloc] init];
    frameAnimation.beginTime = 0.1;
    [frameAnimation setKeyPath:@"contents"];
    frameAnimation.calculationMode = kCAAnimationDiscrete;
    [animationLayer setContents:[imagesArray lastObject]];
    frameAnimation.autoreverses = NO; // If set Yes, transition would be in fade in fade out manner
    frameAnimation.duration = 2.0; // set image duration , it can be predefined float value
    frameAnimation.repeatCount = 5; // this is for inifinite, can be set to any integer value as well
    [frameAnimation setValues:imagesArray];
    [frameAnimation setKeyTimes:keyTimesArray];
    [frameAnimation setRemovedOnCompletion:NO];
    [animationLayer addAnimation:frameAnimation forKey:@"contents"];
    
    if (keyTimesArray)
    {
        [keyTimesArray release];
        keyTimesArray = nil;
    }
    
    if (frameAnimation)
    {
        [frameAnimation release];
        frameAnimation = nil;
    }
    
    return animationLayer;
}

#pragma mark - BuildAnimationSpotlight
- (CALayer*) buildSpotlight:(CGSize)viewBounds
{
    CAShapeLayer *maskLayer = [self createMaskHoleLayer:viewBounds];
    
    return maskLayer;
}

- (CAShapeLayer*) createMaskHoleLayer:(CGSize)viewBounds
{
    CGRect bounds = CGRectMake(viewBounds.width/2, -viewBounds.height/2, viewBounds.width*2, viewBounds.height*2);
    CGFloat kRadius = 80;
    CGRect circleRect = CGRectMake(CGRectGetMidX(bounds) - kRadius,
                                        CGRectGetMidY(bounds) - kRadius,
                                         2 * kRadius, 2 * kRadius);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:circleRect];
    [path appendPath:[UIBezierPath bezierPathWithRect:bounds]];
    
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    circleLayer.path = path.CGPath;
    circleLayer.fillRule = kCAFillRuleEvenOdd;
    circleLayer.bounds = CGPathGetBoundingBox(path.CGPath);
    circleLayer.position = CGPointMake(bounds.size.width/4, bounds.size.height/2);
    circleLayer.opacity = 0;
    
    NSTimeInterval animatedStartTime = 0.1;
    CABasicAnimation *animationOpacityIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationOpacityIn.fromValue = [NSNumber numberWithFloat:0.6];
    animationOpacityIn.toValue = [NSNumber numberWithFloat:0.8];
    animationOpacityIn.repeatCount = 1;
    animationOpacityIn.duration = 1;
    animationOpacityIn.beginTime = animatedStartTime;
    
    CGPoint startPoint = CGPointMake(bounds.size.width/4, bounds.size.height/3);
    CGPoint endPoint = CGPointMake(bounds.size.width/4, bounds.size.height/4);
    CABasicAnimation *animationMove = [CABasicAnimation animationWithKeyPath:@"position"];
    [animationMove setFromValue:[NSValue valueWithCGPoint:startPoint]];
    [animationMove setToValue:[NSValue valueWithCGPoint:endPoint]];
    [animationMove setDuration:animationOpacityIn.duration];
    animationMove.autoreverses = YES;
    animationMove.repeatCount = 1;
    animationMove.beginTime = animatedStartTime;
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = @1.0f;
    scaleAnimation.toValue = @10.0f;
    scaleAnimation.duration = 1.0f;
    scaleAnimation.repeatCount = 1;
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.autoreverses = NO;
    scaleAnimation.beginTime = animatedStartTime + animationMove.duration;
    
    CABasicAnimation *animationOpacityOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationOpacityOut.fromValue = [NSNumber numberWithFloat:0.8];
    animationOpacityOut.toValue = [NSNumber numberWithFloat:0.0];
    animationOpacityOut.repeatCount = 1;
    animationOpacityOut.duration = scaleAnimation.duration;
    animationOpacityOut.beginTime = animatedStartTime + animationMove.duration;

    [circleLayer addAnimation:animationOpacityIn forKey:@"opacityIn"];
    [circleLayer addAnimation:animationMove forKey:@"position"];
    [circleLayer addAnimation:scaleAnimation forKey:@"scale"];
    [circleLayer addAnimation:animationOpacityOut forKey:@"opacityOut"];
    
    return circleLayer;
}

#pragma mark - BuildVideoFrameImage
- (CALayer*) buildVideoFrameImage:(CGSize)viewBounds videoFile:(NSURL*)inputVideoURL startTime:(CMTime)startTime
{
    CALayer *layerImage = [CALayer layer];
    
    UIImage *imageSnap = [self getImageForVideoFrame:inputVideoURL atTime:startTime];
    if (imageSnap)
    {
        // Filter image
        UIImage *imageFilter = [self getFilterFastImage:imageSnap];
        
        // Joint image
//        NSString *imageName = [NSString stringWithFormat:@"attention_%i",(arc4random()%(int)2)+1];
        NSString *imageName = [NSString stringWithFormat:@"attention_1"];
        UIImage *imgOriginal = [UIImage imageNamed:imageName];
        UIImage *imageResult = [self imageJoint:imageFilter fromImage:imgOriginal];
        
        // Layer effect
//        layerImage = [self buildAnimatedScrollLine:viewBounds startTime:1 lineHeight:viewBounds.height/2 image:image];
        layerImage.contents = (id)imageResult.CGImage;
        layerImage.frame = CGRectMake(0, 0, viewBounds.width, viewBounds.height);
        layerImage.opacity = 0.0;
        layerImage.position = CGPointMake(viewBounds.width/2, viewBounds.height/2);
        
        double animatedStartTime = CMTimeGetSeconds(startTime) - 1;
        CABasicAnimation* rotationInAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationInAnimation.toValue = @((2 * M_PI) * -2); // 3 is the number of 360 degree rotations
        rotationInAnimation.duration = 1.0f;
        rotationInAnimation.beginTime = animatedStartTime;
        rotationInAnimation.removedOnCompletion = NO;
        rotationInAnimation.autoreverses = NO;
        rotationInAnimation.fillMode = kCAFillModeForwards;
        rotationInAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        CABasicAnimation *scaleInAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleInAnimation.fromValue = @0.0f;
        scaleInAnimation.toValue = @1.0f;
        scaleInAnimation.removedOnCompletion = NO;
        scaleInAnimation.fillMode = kCAFillModeForwards;
        scaleInAnimation.autoreverses = NO;
        scaleInAnimation.duration = rotationInAnimation.duration + 1.0f;
        scaleInAnimation.beginTime = animatedStartTime;
        scaleInAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        CABasicAnimation *opacityInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityInAnimation.fromValue = [NSNumber numberWithFloat:0.9];
        opacityInAnimation.toValue = [NSNumber numberWithFloat:1.0];
        opacityInAnimation.repeatCount = 1;
        opacityInAnimation.duration = scaleInAnimation.duration;
        opacityInAnimation.beginTime = animatedStartTime;
        
        CABasicAnimation *opacityOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityOutAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        opacityOutAnimation.toValue = [NSNumber numberWithFloat:0.0];
        opacityOutAnimation.repeatCount = 1;
        opacityOutAnimation.duration = opacityInAnimation.duration;
        opacityOutAnimation.beginTime = animatedStartTime + scaleInAnimation.duration;
        
        CABasicAnimation *boundsOutAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsOutAnimation.fromValue = [NSValue valueWithCGRect:layerImage.frame];
        boundsOutAnimation.toValue = [NSValue valueWithCGRect:CGRectZero];
        boundsOutAnimation.repeatCount = 1;
        boundsOutAnimation.duration = opacityOutAnimation.duration;
        boundsOutAnimation.beginTime = opacityOutAnimation.beginTime;
        
        CABasicAnimation *rotationOutAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationOutAnimation.toValue = @((2 * M_PI) * -2);
        rotationOutAnimation.removedOnCompletion = NO;
        rotationOutAnimation.fillMode = kCAFillModeForwards;
        rotationOutAnimation.autoreverses = NO;
        rotationOutAnimation.duration = opacityOutAnimation.duration;
        rotationOutAnimation.beginTime = opacityOutAnimation.beginTime;
        rotationOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        
        [layerImage addAnimation:rotationInAnimation forKey:@"rotationIn"];
        [layerImage addAnimation:scaleInAnimation forKey:@"scaleIn"];
        [layerImage addAnimation:opacityInAnimation forKey:@"opacityIn"];
        
        [layerImage addAnimation:opacityOutAnimation forKey:@"opacityOut"];
        [layerImage addAnimation:boundsOutAnimation forKey:@"boundsOut"];
        [layerImage addAnimation:rotationOutAnimation forKey:@"rotationOut"];
       
        
        // 1. Test image(save to png file)
//        NSError *error = nil;
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//        NSData *dataForPNGFile = UIImagePNGRepresentation(image);
//        if (![dataForPNGFile writeToFile:[documentsDirectory stringByAppendingPathComponent:@"filtered.png"] options:NSAtomicWrite error:&error])
//        {
//            NSLog(@"Error: Couldn't save filter image.");
//        }
        
        // 2. Write to a temporary mov file
//        NSString *tempFilmEffectMov = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/FilmEffect.mov"];
//        unlink([tempFilmEffectMov UTF8String]);
//        
//        NSArray *arrImage = [NSArray arrayWithObjects:image, image, nil];
//        [self writeImages:arrImage toMovieAtPath:tempFilmEffectMov withSize:CGSizeMake(viewBounds.width, viewBounds.height) inDuration:0.5 byFPS:(int32_t)time.timescale];
        
    }
    else
    {
        return nil;
    }

    return layerImage;
}

-(UIImage *) scaleFromImage:(UIImage *)image toSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)imageJoint:(UIImage *)imageTarget fromImage:(UIImage *)imageOriginal
{
    CGSize size = CGSizeMake(imageTarget.size.width,imageTarget.size.height);
    UIGraphicsBeginImageContext(size);
    
    [imageTarget drawInRect:CGRectMake(0, 0, imageTarget.size.width, imageTarget.size.height)];
    
    float multiple = 1.5;
    [imageOriginal drawInRect:CGRectMake((arc4random()%(int)(size.width - imageOriginal.size.width*multiple)), imageTarget.size.height - imageOriginal.size.height, imageOriginal.size.width*multiple, imageOriginal.size.height*multiple)];
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultingImage;
}

- (UIImage*) getImageForVideoFrame:(NSURL *)videoFileURL atTime:(CMTime)time
{
    NSURL *inputUrl = videoFileURL;
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputUrl options:nil];
    NSParameterAssert(asset);
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:time actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef)
    {
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    }
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[[UIImage alloc] initWithCGImage:thumbnailImageRef] autorelease] : nil;
    
    if (thumbnailImageRef)
    {
        CGImageRelease(thumbnailImageRef);
    }
    if (asset)
    {
        [asset release];
    }
    
    if (assetImageGenerator)
    {
        [assetImageGenerator release];
    }
    
    return thumbnailImage;
}

- (UIImage*) getFilterImage:(UIImage*)inputImage
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:inputImage];
//    GPUImageSepiaFilter *stillImageFilter = [[GPUImageSepiaFilter alloc] init];
    GPULookupFilterEx *stillImageFilter = [[GPULookupFilterEx alloc] initWithName:@"milk" isWhiteAndBlack:YES];
    GPUImageVignetteFilter *vignetteImageFilter = [[GPUImageVignetteFilter alloc] init];
    vignetteImageFilter.vignetteEnd = 0.6;
    vignetteImageFilter.vignetteStart = 0.4;
    
    [stillImageSource addTarget:stillImageFilter];
    [stillImageFilter addTarget:vignetteImageFilter];
    
    [vignetteImageFilter useNextFrameForImageCapture];
    [stillImageSource processImage];
    
    UIImage *currentFilteredImage = [vignetteImageFilter imageFromCurrentFramebuffer];
    
    [vignetteImageFilter removeAllTargets];
    [stillImageSource release];
    [stillImageFilter release];
    [vignetteImageFilter release];
    
    return currentFilteredImage;
}

- (UIImage*) getFilterFastImage:(UIImage*)inputImage
{
    GPUImageVignetteFilter *stillImageFilter = [[GPUImageVignetteFilter alloc] init];
    stillImageFilter.vignetteEnd = 0.6;
    stillImageFilter.vignetteStart = 0.4;

    UIImage *quickFilteredImage = [stillImageFilter imageByFilteringImage:inputImage];
    [stillImageFilter release];
    stillImageFilter = nil;
    
    return quickFilteredImage;
}

- (CVPixelBufferRef) pixelBufferFromImage: (UIImage*) image
{
    @autoreleasepool
    {
        CGImageRef cgimage = [image CGImage];
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                 nil];
        
        CVPixelBufferRef pxbuffer = NULL;
        
        float width =  CGImageGetWidth(cgimage);
        float height = CGImageGetHeight(cgimage);
        
        
        CVPixelBufferCreate(kCFAllocatorDefault,width,
                            height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)(options),
                            &pxbuffer);
        
        CVPixelBufferLockBaseAddress(pxbuffer, 0);
        
        void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
        
        NSParameterAssert(pxdata != NULL);
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pxdata, width,
                                                     height, 8, 4*width, rgbColorSpace,
                                                     (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        
        
        CGContextConcatCTM(context, CGAffineTransformMakeRotation(-M_PI/2));
        
        CGContextDrawImage(context, CGRectMake(-height, 0, height, width), cgimage);
        
        CGColorSpaceRelease(rgbColorSpace);
        CGContextRelease(context);
        
        CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
        
        return pxbuffer;
    }
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image andSize:(CGSize) size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          size.width,
                                          size.height,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if (status != kCVReturnSuccess)
    {
        NSLog(@"Failed to create pixel buffer");
    }
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

// Add film effect
- (void) writeImages:(NSArray *)imagesArray toMovieAtPath:(NSString *)path withSize:(CGSize)size
          inDuration:(double)numberOfSecondsPerFrame byFPS:(int32_t)fps
{
    // Wire the writer:
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                            fileType:AVFileTypeQuickTimeMovie
                                                               error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                             assetWriterInputWithMediaType:AVMediaTypeVideo
                                             outputSettings:videoSettings];
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    
    // Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    // Write some samples:
    CVPixelBufferRef buffer = NULL;
    
    int frameCount = 0;
    double frameDuration = fps * numberOfSecondsPerFrame;
    
    NSLog(@"**************************************************");
    for(UIImage * img in imagesArray)
    {
        buffer = [self pixelBufferFromImage:img];
        
        CVPixelBufferLockBaseAddress(buffer, 0);
        
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData && videoWriter.status == AVAssetWriterStatusWriting)
            {
                // print out status
                NSLog(@"Processing video frame (%d,%lu)",frameCount,(unsigned long)[imagesArray count]);
                
                CMTime frameTime = CMTimeMake(frameCount*frameDuration,(int32_t)fps);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                if(!append_ok)
                {
                    NSError *error = videoWriter.error;
                    if(error!=nil)
                    {
                        NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
                    }
                }
            }
            else
            {
                NSLog(@"adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            
            j++;
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, 0);
        
        if (!append_ok)
        {
            NSLog(@"error appending image %d times %d\n, with error.", frameCount, j);
        }
        
        frameCount++;
        
        if(buffer != NULL)
        {
            CVBufferRelease(buffer);
            buffer = NULL;
        }
    }
    
    NSLog(@"**************************************************");
    
    
    // Finish the session
    [videoWriterInput markAsFinished];
    [videoWriter finishWriting];

    [videoWriter release];
    
    NSLog(@"Finish insert image into video.");
}

#pragma mark - Basic Animation
-(CAKeyframeAnimation *)animationPageUrl:(float)duration
{
    // page-curl effect
    CATransform3D transform = CATransform3DIdentity;
    float zDistanse = 800.0;
    transform.m34 = 1.0 / -zDistanse;
    
    CATransform3D transform1 = CATransform3DRotate(transform, -M_PI_2/10, 0, 1, 0);
    CATransform3D transform2 = CATransform3DRotate(transform, -M_PI_2, 0, 1, 0);
    
    CAKeyframeAnimation* keyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    keyframeAnimation.duration = duration;
    keyframeAnimation.values = [NSArray arrayWithObjects:
                                [NSValue valueWithCATransform3D:transform],
                                [NSValue valueWithCATransform3D:transform1],
                                [NSValue valueWithCATransform3D:transform2],
                                nil];
    keyframeAnimation.keyTimes = [NSArray arrayWithObjects:
                                  [NSNumber numberWithFloat:0],
                                  [NSNumber numberWithFloat:.2],
                                  [NSNumber numberWithFloat:1.0],
                                  nil];
    keyframeAnimation.timingFunctions = [NSArray arrayWithObjects:
                                         [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                         [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                         nil];
    keyframeAnimation.removedOnCompletion = NO;
    keyframeAnimation.fillMode = kCAFillModeForwards;
    
    return keyframeAnimation;
}

// 旋转
-(CABasicAnimation *)animationRotation:(float)duration degree:(float)degree direction:(int)direction repeatCount:(int)repeatCount
{
    CATransform3D rotationTransform  = CATransform3DMakeRotation(degree, 0, 0,direction);
    CABasicAnimation* animation;
    animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    
    animation.toValue = [NSValue valueWithCATransform3D:rotationTransform];
    animation.duration = duration;
    animation.autoreverses = NO;
    animation.cumulative = YES;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.repeatCount = repeatCount;
    animation.delegate = self;
    
    return animation;
}

// 缩放
-(CABasicAnimation *)animationScale:(NSNumber *)Multiple orgin:(NSNumber *)orginMultiple durTimes:(float)time Rep:(float)repeatTimes
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = orginMultiple;
    animation.toValue = Multiple;
    animation.duration = time;
    animation.autoreverses = YES;
    animation.repeatCount = repeatTimes;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    
    return animation;
}

// 点移动
-(CABasicAnimation *)animationMovePoint:(float)time point:(CGPoint)point
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation"];
    animation.toValue = [NSValue valueWithCGPoint:point];
    animation.removedOnCompletion = NO;
    animation.duration = time;
    animation.fillMode = kCAFillModeForwards;
    
    return animation;
}

// 横向移动
-(CABasicAnimation *)animationMoveX:(float)time X:(NSNumber *)x
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.toValue = x;
    animation.duration = time;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    
    return animation;
}

// 纵向移动
-(CABasicAnimation *)animationMoveY:(float)time Y:(NSNumber *)y
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    animation.toValue = y;
    animation.duration = time;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    
    return animation;
}

// 有闪烁次数的动画
-(CABasicAnimation *)animationOpacityTimes:(float)repeatTimes durTimes:(float)time;
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:0.0];
    animation.repeatCount = repeatTimes;
    animation.duration = time;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.autoreverses = YES;
    
    return  animation;
}

// 路径动画
-(CAKeyframeAnimation *)keyframeAniamtion:(CGMutablePathRef)path durTimes:(float)time Rep:(float)repeatTimes
{
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.path = path;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.autoreverses = NO;
    animation.duration = time;
    animation.repeatCount = repeatTimes;
    
    return animation;
}

// Z轴旋转
-(CABasicAnimation *)animationRotationZ:(float)repeatTimes durationTimes:(float)time
{
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    rotation.toValue = [NSNumber numberWithFloat:-4 * M_PI];
    rotation.duration = time;
    rotation.repeatCount = repeatTimes;
    rotation.autoreverses = YES;
    rotation.beginTime = 1.0;
    
    return  rotation;
}

#pragma mark - BuildComposition
- (void)buildSequenceComposition:(AVMutableComposition *)composition
{
	CMTime nextClipStartTime = kCMTimeZero;
	NSInteger i;
	
	// No transitions: place clips into one video track and one audio track in composition.
	
	AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	
	for (i = 0; i < [_clips count]; i++ )
    {
		AVURLAsset *asset = [_clips objectAtIndex:i];
		NSValue *clipTimeRange = [_clipTimeRanges objectAtIndex:i];
		CMTimeRange timeRangeInAsset;
		if (clipTimeRange)
			timeRangeInAsset = [clipTimeRange CMTimeRangeValue];
		else
			timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, [asset duration]);
		
		AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
		[compositionVideoTrack insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:nil];
		
        // 视频文件可能没有音频轨道，静音
        if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0)
        {
            AVAssetTrack *clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            [compositionAudioTrack insertTimeRange:timeRangeInAsset ofTrack:clipAudioTrack atTime:nextClipStartTime error:nil];
		}
        
		// Note: This is largely equivalent:
		// [composition insertTimeRange:timeRangeInAsset ofAsset:asset atTime:nextClipStartTime error:NULL];
		// except that if the video tracks dimensions do not match, additional video tracks will be added to the composition.

		nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration);
	}
}

- (void)buildTransitionComposition:(AVMutableComposition *)composition andVideoComposition:(AVMutableVideoComposition *)videoComposition
{
	CMTime nextClipStartTime = kCMTimeZero;
	NSInteger i;

	// Make transitionDuration no greater than half the shortest clip duration.
	CMTime transitionDuration = self.transitionDuration;
	for (i = 0; i < [_clips count]; i++ )
    {
		NSValue *clipTimeRange = [_clipTimeRanges objectAtIndex:i];
		if (clipTimeRange)
        {
			CMTime halfClipDuration = [clipTimeRange CMTimeRangeValue].duration;
			halfClipDuration.timescale *= 2; // You can halve a rational by doubling its denominator.
			transitionDuration = CMTimeMinimum(transitionDuration, halfClipDuration);
		}
	}
	
	// Add two video tracks and two audio tracks.
	AVMutableCompositionTrack *compositionVideoTracks[2];
	AVMutableCompositionTrack *compositionAudioTracks[2];
	compositionVideoTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	compositionVideoTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	compositionAudioTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	compositionAudioTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	
	CMTimeRange *passThroughTimeRanges = alloca(sizeof(CMTimeRange) * [_clips count]);
	CMTimeRange *transitionTimeRanges = alloca(sizeof(CMTimeRange) * [_clips count]);
	
	// Place clips into alternating video & audio tracks in composition, overlapped by transitionDuration.
	for (i = 0; i < [_clips count]; i++ )
    {
		NSInteger alternatingIndex = i % 2; // alternating targets: 0, 1, 0, 1, ...
		AVURLAsset *asset = [_clips objectAtIndex:i];
		NSValue *clipTimeRange = [_clipTimeRanges objectAtIndex:i];
		CMTimeRange timeRangeInAsset;
		if (clipTimeRange)
			timeRangeInAsset = [clipTimeRange CMTimeRangeValue];
		else
			timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, [asset duration]);
		
		AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
		[compositionVideoTracks[alternatingIndex] insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:nil];
		
        // 视频文件可能没有音频轨道，静音
        if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0)
        {
            AVAssetTrack *clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            [compositionAudioTracks[alternatingIndex] insertTimeRange:timeRangeInAsset ofTrack:clipAudioTrack atTime:nextClipStartTime error:nil];
		}
		
		// Remember the time range in which this clip should pass through.
		// Every clip after the first begins with a transition.
		// Every clip before the last ends with a transition.
		// Exclude those transitions from the pass through time ranges.
		passThroughTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, timeRangeInAsset.duration);
		if (i > 0)
        {
			passThroughTimeRanges[i].start = CMTimeAdd(passThroughTimeRanges[i].start, transitionDuration);
			passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
		}
		if (i+1 < [_clips count])
        {
			passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
		}
		
		// The end of this clip will overlap the start of the next by transitionDuration.
		// (Note: this arithmetic falls apart if timeRangeInAsset.duration < 2 * transitionDuration.)
		nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration);
		nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
		
		// Remember the time range for the transition to the next item.
		transitionTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
	}
	
	// Set up the video composition if we are to perform crossfade or push transitions between clips.
	NSMutableArray *instructions = [NSMutableArray array];

	// Cycle between "pass through A", "transition from A to B", "pass through B", "transition from B to A".
	for (i = 0; i < [_clips count]; i++ )
    {
		NSInteger alternatingIndex = i % 2; // alternating targets
		
		// Pass through clip i.
		AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
		passThroughInstruction.timeRange = passThroughTimeRanges[i];
        
		AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[alternatingIndex]];
		passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
		[instructions addObject:passThroughInstruction];
		
		if (i+1 < [_clips count])
        {
			// Add transition from clip i to clip i+1.
			AVMutableVideoCompositionInstruction *transitionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
			transitionInstruction.timeRange = transitionTimeRanges[i];
            
			AVMutableVideoCompositionLayerInstruction *fromLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[alternatingIndex]];
			AVMutableVideoCompositionLayerInstruction *toLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[1-alternatingIndex]];
			
			if (self.transitionType == TransitionTypeCrossFade)
            {
				// Fade out the fromLayer by setting a ramp from 1.0 to 0.0.
				[fromLayer setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:transitionTimeRanges[i]];
			}
			else if (self.transitionType == TransitionTypePush)
            {
				// Set a transform ramp on fromLayer from identity to all the way left of the screen.
				[fromLayer setTransformRampFromStartTransform:CGAffineTransformIdentity toEndTransform:CGAffineTransformMakeTranslation(-composition.naturalSize.width, 0.0) timeRange:transitionTimeRanges[i]];
                
				// Set a transform ramp on toLayer from all the way right of the screen to identity.
				[toLayer setTransformRampFromStartTransform:CGAffineTransformMakeTranslation(+composition.naturalSize.width, 0.0) toEndTransform:CGAffineTransformIdentity timeRange:transitionTimeRanges[i]];
			}
			
			transitionInstruction.layerInstructions = [NSArray arrayWithObjects:fromLayer, toLayer, nil];
			[instructions addObject:transitionInstruction];
		}
	}
		
	videoComposition.instructions = instructions;
}

- (void)addCommentaryTrackToComposition:(AVMutableComposition *)composition withAudioMix:(AVMutableAudioMix *)audioMix
{
	NSInteger i;
	NSArray *tracksToDuck = [composition tracksWithMediaType:AVMediaTypeAudio]; // before we add the commentary
	
	// 1. Clip commentary duration to composition duration.
	CMTimeRange commentaryTimeRange = CMTimeRangeMake(self.commentaryStartTime, self.commentary.duration);
	if (CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(commentaryTimeRange), >, [composition duration]))
		commentaryTimeRange.duration = CMTimeSubtract([composition duration], commentaryTimeRange.start);
	
	// 2. Add the commentary track.
	AVMutableCompositionTrack *compositionCommentaryTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack * commentaryTrack = [[self.commentary tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
	[compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, commentaryTimeRange.duration) ofTrack:commentaryTrack atTime:commentaryTimeRange.start error:nil];
	
    // 3. Fade in for bgMusic
    CMTime fadeTime = CMTimeMake(1, 1);
    CMTimeRange startRange = CMTimeRangeMake(kCMTimeZero, fadeTime);
    NSMutableArray *trackMixArray = [NSMutableArray array];
    AVMutableAudioMixInputParameters *trackMixComentray = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:commentaryTrack];
    [trackMixComentray setVolumeRampFromStartVolume:0.0f toEndVolume:0.2f timeRange:startRange];
	[trackMixArray addObject:trackMixComentray];
	
	// 4. Fade in & Fade out for original voices
	for (i = 0; i < [tracksToDuck count]; i++)
    {
        CMTimeRange timeRange = [[tracksToDuck objectAtIndex:i] timeRange];
        if (CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(timeRange), ==, kCMTimeInvalid))
        {
            break;
        }
        
		CMTime halfSecond = CMTimeMake(1, 2);
		CMTime startTime = CMTimeSubtract(timeRange.start, halfSecond);
		CMTime endRangeStartTime = CMTimeAdd(timeRange.start, timeRange.duration);
		CMTimeRange endRange = CMTimeRangeMake(endRangeStartTime, halfSecond);
        if (startTime.value < 0)
        {
            startTime.value = 0;
        }
        
		[trackMixComentray setVolumeRampFromStartVolume:0.5f toEndVolume:0.2f timeRange:CMTimeRangeMake(startTime, halfSecond)];
		[trackMixComentray setVolumeRampFromStartVolume:0.2f toEndVolume:0.5f timeRange:endRange];
		[trackMixArray addObject:trackMixComentray];
	}
    
    // 5. Fade out for bgMusic
//    CMTime endRangeStartTime = CMTimeSubtract([composition duration], fadeTime);
//	CMTimeRange endRange = CMTimeRangeMake(endRangeStartTime, fadeTime);
//    [trackMixComentray setVolumeRampFromStartVolume:1.0f toEndVolume:0.0f timeRange:endRange];
//	[trackMixArray addObject:trackMixComentray];

	audioMix.inputParameters = trackMixArray;
}

- (void)buildPassThroughVideoComposition:(AVMutableVideoComposition *)videoComposition forComposition:(AVMutableComposition *)composition
{
	// Make a "pass through video track" video composition.
	AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
	
	AVAssetTrack *videoTrack = [[composition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
	AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
	
	passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
	videoComposition.instructions = [NSArray arrayWithObject:passThroughInstruction];
}

- (void)buildCompositionObjectsForPlayback:(BOOL)forPlayback
{	
	CGSize videoSize = [[_clips objectAtIndex:0] naturalSize];
	AVMutableComposition *composition = [AVMutableComposition composition];
	AVMutableVideoComposition *videoComposition = nil;
	AVMutableAudioMix *audioMix = nil;
	CALayer *animatedTitleLayer = nil;
	
	composition.naturalSize = videoSize;
	
	if (self.transitionType == TransitionTypeNone)
    {
		// No transitions: place clips into one video track and one audio track in composition.
		[self buildSequenceComposition:composition];
	}
	else
    {
		// With transitions:
		// Place clips into alternating video & audio tracks in composition, overlapped by transitionDuration.
		// Set up the video composition to cycle between "pass through A", "transition from A to B", 
		// "pass through B", "transition from B to A".
		videoComposition = [AVMutableVideoComposition videoComposition];
		[self buildTransitionComposition:composition andVideoComposition:videoComposition];
	}
	
	// If one is provided, add a commentary track and duck all other audio during it.
	if (self.commentary)
    {
		// Add the commentary track and duck all other audio during it.
		audioMix = [AVMutableAudioMix audioMix];
		[self addCommentaryTrackToComposition:composition withAudioMix:audioMix];
	}
	
	// Set up Core Animation layers to contribute a title animation overlay if we have a title set.
	if (self.titleText)
    {
		animatedTitleLayer = [self buildAnimationStarText:videoSize text:self.titleText];
		
		if (! forPlayback)
        {
			// For export: build a Core Animation tree that contains both the animated title and the video.
			CALayer *parentLayer = [CALayer layer];
			CALayer *videoLayer = [CALayer layer];
			parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
			videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
			[parentLayer addSublayer:videoLayer];
			[parentLayer addSublayer:animatedTitleLayer];

			if (! videoComposition)
            {
				// No transition set -- make a "pass through video track" video composition so we can include the Core Animation tree as a post-processing stage.
				videoComposition = [AVMutableVideoComposition videoComposition];
				
				[self buildPassThroughVideoComposition:videoComposition forComposition:composition];
			}
			
			videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
		}
	}
	
	if (videoComposition)
    {
		// Every videoComposition needs these properties to be set:
		videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
		videoComposition.renderSize = videoSize;
	}
	
	self.composition = composition;
	self.videoComposition = videoComposition;
	self.audioMix = audioMix;

	self.synchronizedLayer = nil;
	
	if (forPlayback)
    {
#if TARGET_OS_EMBEDDED
		// Render high-def movies at half scale for real-time playback (device-only).
		if (videoSize.width > 640)
			videoComposition.renderScale = 0.5;
#endif // TARGET_OS_EMBEDDED
		
		AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:composition];
		playerItem.videoComposition = videoComposition;
		playerItem.audioMix = audioMix;
		self.playerItem = playerItem;

		if (animatedTitleLayer)
        {
			// Build an AVSynchronizedLayer that contains the animated title.
			self.synchronizedLayer = [AVSynchronizedLayer synchronizedLayerWithPlayerItem:self.playerItem];
			self.synchronizedLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height);
			[self.synchronizedLayer addSublayer:animatedTitleLayer];
		}
	}
}

- (void)getPlayerItem:(AVPlayerItem**)playerItemOut andSynchronizedLayer:(AVSynchronizedLayer**)synchronizedLayerOut
{
	if (playerItemOut)
    {
		*playerItemOut = _playerItem;
	}
    
	if (synchronizedLayerOut)
    {
		*synchronizedLayerOut = _synchronizedLayer;
	}
}

- (AVAssetImageGenerator*)assetImageGenerator
{
	AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.composition];
	generator.videoComposition = self.videoComposition;
	return generator;
}

- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName
{
	AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:presetName];
	session.videoComposition = self.videoComposition;
	session.audioMix = self.audioMix;

	return [session autorelease];
}

- (void)dealloc 
{
	[_clips release];
	[_clipTimeRanges release];

	[_commentary release];
	[_titleText release];
	
	
	[_composition release];
	[_videoComposition release];
	[_audioMix release];
	
	[_playerItem release];
	[_synchronizedLayer release];

    [super dealloc];
}

@end
