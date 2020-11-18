//
//  Waver.m
//  Waver
//
//  Created by kevinzhow on 14/12/14.
//  Copyright (c) 2014年 Catch Inc. All rights reserved.
//

#import "Waver.h"

@interface Waver ()

@property (nonatomic) CGFloat phase;//相位
@property (nonatomic) CGFloat amplitude;//振幅
@property (nonatomic) NSMutableArray * waves;
@property (nonatomic) CGFloat waveHeight;
@property (nonatomic) CGFloat waveWidth;
@property (nonatomic) CGFloat waveMid;
@property (nonatomic) CGFloat maxAmplitude;//最大振幅
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation Waver


- (id)init{
    if(self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    self.waves = [NSMutableArray new];
    
    self.frequency = 1.2f;//频率
    
    self.amplitude = 1.0f;//振幅
    self.idleAmplitude = 0.01f;
    
    self.numberOfWaves = 5;//波浪线的数量
    self.phaseShift = -0.25f;//相位偏移
    self.density = 1.f;//密度
    
    self.waveColor = [UIColor colorWithRed:212/255.0 green:59/255.0 blue:54/255.0 alpha:1.0];
    self.mainWaveWidth = 2.0f;//主波浪线的线条宽
    self.decorativeWavesWidth = 1.0f;//其他波浪线的线条宽
    
	self.waveHeight = CGRectGetHeight(self.bounds);//波浪线高度
    self.waveWidth  = CGRectGetWidth(self.bounds);//波浪线宽度
    self.waveMid    = self.waveWidth / 2.0f;//波浪线的中点
    self.maxAmplitude = self.waveHeight - 4.0f;//最大振幅
}

- (void)setWaverLevelCallback:(void (^)(Waver * waver))waverLevelCallback {
    _waverLevelCallback = waverLevelCallback;

    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(invokeWaveCallback)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    //先设置波浪线layer
    for(int i=0; i < self.numberOfWaves; i++)
    {
        CAShapeLayer *waveline = [CAShapeLayer layer];
        waveline.fillColor     = [[UIColor clearColor] CGColor];
        [waveline setLineWidth:(i==0 ? self.mainWaveWidth : self.decorativeWavesWidth)];
        CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
        CGFloat multiplier = MIN(1.0, (progress / 3.0f * 2.0f) + (1.0f / 3.0f));
		UIColor *color = [self.waveColor colorWithAlphaComponent:(i == 0 ? 1.0 : 1.0 * multiplier * 0.4)];
		waveline.strokeColor = color.CGColor;
        [self.layer addSublayer:waveline];
        [self.waves addObject:waveline];
    }
    
}

- (void)invokeWaveCallback{
    self.waverLevelCallback(self);
}

- (void)setLevel:(CGFloat)level{
    _level = level;
    
    self.phase += self.phaseShift; // Move the wave
    
    self.amplitude = fmax( level, self.idleAmplitude);
    [self updateMeters];
}


- (void)updateMeters{
    
	self.waveHeight = CGRectGetHeight(self.bounds);
	self.waveWidth  = CGRectGetWidth(self.bounds);
	self.waveMid    = self.waveWidth / 2.0f;
	self.maxAmplitude = self.waveHeight - 4.0f;
	
//    UIGraphicsBeginImageContext(self.frame.size);
    
    for(int i=0; i < self.numberOfWaves; i++) {

        UIBezierPath *wavelinePath = [UIBezierPath bezierPath];

        //Progress是一个介于1.0和-0.5之间的值，
        //由当前波idx决定，idx用于改变波的振幅。
        CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
        CGFloat normedAmplitude = (1.5f * progress - 0.5f) * self.amplitude;
        
        for(CGFloat x = 0; x<self.waveWidth + self.density; x += self.density) {
            //Thanks to https://github.com/stefanceriu/SCSiriWaveformView
            // We use a parable to scale the sinus wave, that has its peak in the middle of the view.
            CGFloat scaling = 1 - pow(x / self.waveMid  - 1, 2); // make center bigger
            
            CGFloat y = scaling * self.maxAmplitude * normedAmplitude * sinf(2 * M_PI *(x / self.waveWidth) * self.frequency + self.phase) + (self.waveHeight * 0.5);
            
            if (x==0) {
                [wavelinePath moveToPoint:CGPointMake(x, y)];
            }
            else {
                [wavelinePath addLineToPoint:CGPointMake(x, y)];
            }
        }
        
        CAShapeLayer *waveline = [self.waves objectAtIndex:i];
        waveline.path = [wavelinePath CGPath];
    }
    
//    UIGraphicsEndImageContext();
}

- (void)dealloc
{
    [_displayLink invalidate];
}

@end
