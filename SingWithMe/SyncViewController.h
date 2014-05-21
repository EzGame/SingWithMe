//
//  SyncViewController.h
//  SingWithMe
//
//  Created by David Zhang on 2014-05-19.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EZAudio.h"

@interface SyncViewController : UIViewController
<EZAudioFileDelegate,
EZOutputDataSource>

@property (weak, nonatomic) IBOutlet EZAudioPlotGL  *audioPlot;
@property (weak, nonatomic) IBOutlet UIButton       *startButton;
@property (weak, nonatomic) IBOutlet UIButton       *pauseButton;
@property (weak, nonatomic) IBOutlet UITextView     *lyricsTextView;
@property (nonatomic, strong) NSString              *lyrics;
@property (nonatomic, strong) NSMutableArray        *lyricStack;
@property (nonatomic, strong) NSURL                 *songURL;
@property (nonatomic, strong) EZAudioFile           *songFile;
@end
