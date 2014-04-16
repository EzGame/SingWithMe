//
//  ViewController.h
//  SingWithMe
//
//  Created by David Zhang on 2014-04-05.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EZAudio.h"
#import "EZAudioPlotGL+PlotWithFreq.h"
#import "EZAudioFile+AudioWithoutVocals.h"
#import "SingModel.h"

@interface SingViewController: UIViewController
<MPMediaPickerControllerDelegate,
    EZAudioFileDelegate,
    EZMicrophoneDelegate,
    EZOutputDataSource>

@property (weak, nonatomic) IBOutlet UIButton       *pickSongButton;
@property (weak, nonatomic) IBOutlet UIButton       *playToggleButton;
@property (weak, nonatomic) IBOutlet UILabel        *currentSongLabel;
@property (weak, nonatomic) IBOutlet UILabel        *noteDebugLabel;
@property (weak, nonatomic) IBOutlet EZAudioPlotGL  *currentAudioPlot;
@property (weak, nonatomic) IBOutlet EZAudioPlotGL  *currentMicPlot;

- (IBAction) playToggle:(id)sender;
- (IBAction) pickSong:(id)sender;
@end
