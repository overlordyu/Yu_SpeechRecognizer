//
//  Waver.h
//  Waver
//
//  Created by kevinzhow on 14/12/14.
//  Copyright (c) 2014年 Catch Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Waver : UIView

@property (nonatomic, copy) void (^waverLevelCallback)(Waver * waver);

///波峰数
@property (nonatomic) NSUInteger numberOfWaves;
///波浪线的颜色
@property (nonatomic) UIColor * waveColor;

@property (nonatomic) CGFloat level;
//主波浪线的线条宽
@property (nonatomic) CGFloat mainWaveWidth;
//其他波浪线的线条宽
@property (nonatomic) CGFloat decorativeWavesWidth;

@property (nonatomic) CGFloat idleAmplitude;
//频率
@property (nonatomic) CGFloat frequency;
///振幅
@property (nonatomic, readonly) CGFloat amplitude;
//密度
@property (nonatomic) CGFloat density;
//相位变化、相位移
@property (nonatomic) CGFloat phaseShift;

@property (nonatomic, readonly) NSMutableArray * waves;

@end
