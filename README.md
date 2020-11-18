# Yu_SpeechRecognizer
仿今日头条语音搜索功能，语音识别器，语音转文字，语音搜索，根据音量大小绘制酷炫波纹。

```
 //创建波浪线，根据录音音量大小变化
    Waver * waver = [[Waver alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)/2.0 - 50.0, CGRectGetWidth(self.view.bounds), 100.0)];
    
    __block AVAudioRecorder *weakRecorder = self.recorder;
    
    waver.waverLevelCallback = ^(Waver * waver) {
        
        [weakRecorder updateMeters];
        
        CGFloat normalizedValue = pow (10, [weakRecorder averagePowerForChannel:0] / 40);
        
        waver.level = normalizedValue;
        
    };
    [self.view addSubview:waver];
```
```
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
```
