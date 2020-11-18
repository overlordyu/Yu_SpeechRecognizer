//
//  ViewController.m
//  Waver
//
//  Created by kevinzhow on 14/12/14.
//  Copyright (c) 2014年 Catch Inc. All rights reserved.
//

#define KScreenHeight ([UIScreen mainScreen].bounds.size.height)
#define KScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define KRGB(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define KSelfHeight self.view.bounds.size.height
#define KSelfWidth self.view.bounds.size.width

#import "WaveViewController.h"
#import "Waver.h"
#import <AVFoundation/AVFoundation.h>

#import <Speech/Speech.h>

@interface WaveViewController ()<SFSpeechRecognizerDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;


///语音识别器
@property(nonatomic,strong)SFSpeechRecognizer *speechRecognizer;
///语音识别请求
@property(nonatomic,strong)SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
///语音识别任务器
@property(nonatomic,strong)SFSpeechRecognitionTask *recognitionTask;
///语音控制器
@property(nonatomic,strong)AVAudioEngine *audioEngine;

//开始录音还是停止录音
@property(nonatomic,strong)UIButton *switchBtn;
@property(nonatomic,strong)UILabel *switchTipLab;
///显示语音转文字
@property(nonatomic,strong)UILabel *speechLabel;

@end

@implementation WaveViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //创建录音器
    [self setupRecorder];
    
    //创建波浪线，根据录音音量大小变化
    Waver * waver = [[Waver alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)/2.0 - 50.0, CGRectGetWidth(self.view.bounds), 100.0)];
    
    __block AVAudioRecorder *weakRecorder = self.recorder;
    
    waver.waverLevelCallback = ^(Waver * waver) {
        
        [weakRecorder updateMeters];
        
        CGFloat normalizedValue = pow (10, [weakRecorder averagePowerForChannel:0] / 40);
        
        waver.level = normalizedValue;
        
    };
    [self.view addSubview:waver];
    
    [self createSwitchBtn];
    ///发送语音认证请求前，首先要判断设备是否支持语音识别功能
    [self getRecognizerAuthorizationStatus];
}

-(void)setupRecorder
{
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    
    NSDictionary *settings = @{
AVSampleRateKey:          [NSNumber numberWithFloat: 44100.0],
AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatAppleLossless],
AVNumberOfChannelsKey:    [NSNumber numberWithInt: 2],
AVEncoderAudioQualityKey: [NSNumber numberWithInt: AVAudioQualityMin]
};
    
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if(error) {
        NSLog(@"Ups, could not create recorder %@", error);
        return;
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
    
    [self.recorder prepareToRecord];
    [self.recorder setMeteringEnabled:YES];
    [self.recorder record];
}

#pragma mark ---------------------语音转文字-----------------------
///发送语音认证请求前，首先要判断设备是否支持语音识别功能
-(void)getRecognizerAuthorizationStatus{
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:{
                NSLog(@"语音可以识别！");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.switchBtn.enabled = YES;
                });
            }
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied || SFSpeechRecognizerAuthorizationStatusNotDetermined:{
                NSLog(@"用户未授权语音识别的权限！");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.switchBtn.enabled = NO;
                });
            }
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:{
                NSLog(@"识别失败，语音识别在这台设备上受到限制！");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.switchBtn.enabled = NO;
                });
            }
                break;
            default:{
                NSLog(@"识别失败，请稍后重试！");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.switchBtn.enabled = NO;
                });
            }
                break;
        }
    }];
}

///创建语音识别器
-(SFSpeechRecognizer *)speechRecognizer{
    if (!_speechRecognizer) {
        NSLocale *localeID = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-CN en-US"];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:localeID];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}

///创建语音控制器
-(AVAudioEngine *)audioEngine{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}

///创建控制按钮
-(void)createSwitchBtn{
    _switchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _switchBtn.backgroundColor = [UIColor whiteColor];
    _switchBtn.frame = CGRectMake((KSelfWidth-60)/2.0f, KSelfHeight-50-60, 60, 60);
    [_switchBtn setImage:[UIImage imageNamed:@"语音.png"] forState:UIControlStateNormal];
    [self.view addSubview:_switchBtn];
    [_switchBtn addTarget:self action:@selector(switchBtnTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_switchBtn addTarget:self action:@selector(switchBtnTouchUp:) forControlEvents:UIControlEventTouchUpOutside|UIControlEventTouchUpInside];
    
    _switchBtn.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    _switchBtn.layer.cornerRadius = _switchBtn.bounds.size.height/2.0;
    _switchBtn.layer.masksToBounds = YES;
    _switchBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _switchBtn.layer.borderWidth = 1.0;
    
    _switchTipLab = [[UILabel alloc] initWithFrame:CGRectMake(0, KSelfHeight-20-20, KSelfWidth, 20)];
    _switchTipLab.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_switchTipLab];
    _switchTipLab.textColor = [UIColor lightGrayColor];
    _switchTipLab.textAlignment = NSTextAlignmentCenter;
    _switchTipLab.font = [UIFont systemFontOfSize:13];
    _switchTipLab.text = @"按下说话搜索";
    
    ///顶部显示语音搜索结果：
    _speechLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, KSelfWidth, 20)];
    _speechLabel.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_speechLabel];
    _speechLabel.textColor = [UIColor lightGrayColor];
    _speechLabel.textAlignment = NSTextAlignmentCenter;
    _speechLabel.font = [UIFont systemFontOfSize:13];
    _speechLabel.text = @"";
}

-(void)switchBtnTouchDown:(UIButton *)btn{
    NSLog(@"按下！！！");
    _switchTipLab.text = @"松开立即搜索";
    _speechLabel.text = @"正在聆听说话";
    ///开始录音
    [self startRecording];

}
-(void)switchBtnTouchUp:(UIButton *)btn{
    NSLog(@"松开！！！");
    _switchTipLab.text = @"按下说话搜索";
    if ([_speechLabel.text isEqualToString:@"正在聆听说话"]) {
        _speechLabel.text = @"";
    }
    ///停止录音
    [self endRecording];
}

///开始录音
-(void)startRecording{
    ///先让之前语音识别任务停止
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    //set session category
    BOOL isSetCategory = [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    //set session category with options
    BOOL isSetMode = [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    //set session category and mode with options
    BOOL isSetActive = [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    if (isSetCategory || isSetMode || isSetActive) {
        NSLog(@"录音功能正常");
        ///创建语音识别请求
        [self createRecognitionRequest];
    }else{
        NSLog(@"不支持录音功能");
    }
}

///创建语音识别请求
-(void)createRecognitionRequest{
    //创建语音识别请求
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    _recognitionRequest.shouldReportPartialResults = YES;
    
    //创建语音识别任务
    __weak typeof(self) weakSelf = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        BOOL isFinal = NO;
        if (result) {
            ///获取语音转文字的识别结果：
            strongSelf.speechLabel.text = [[result bestTranscription] formattedString];
            NSLog(@"---%@----",[[result bestTranscription] formattedString]);
            ///假如识别成功，则为YES
            isFinal = [result isFinal];
        }
    }];
    
    AVAudioFormat *audioFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个,不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:audioFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.recognitionRequest) {
            [strongSelf.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    NSError *error;
    BOOL isStart = [self.audioEngine startAndReturnError:&error];
    if (!isStart) {
        NSLog(@"语音识别启动失败！");
    }
    //self.speechLabel.text = @"正在识别语音";
}

///停止录音
-(void)endRecording{
    ///语音控制器停止
    [self.audioEngine stop];
    
    ///语音识别请求停止
    if (_recognitionRequest) {
        [_recognitionRequest endAudio];
        _recognitionRequest = nil;
    }
    
    ///语音识别任务停止
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
}

#pragma mark---------SFSpeechRecognizerDelegate---------------
///当给定识别器的可用性发生更改时调用,比如用户重新授权了：
-(void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if (available) {
        NSLog(@"语音可以识别！");
        [self getRecognizerAuthorizationStatus];
    }else{
        NSLog(@"用户未授权语音识别的权限！");
    }
}

@end
