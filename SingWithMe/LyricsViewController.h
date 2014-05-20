//
//  LyricsViewController.h
//  SingWithMe
//
//  Created by David Zhang on 2014-05-19.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface LyricsViewController : UIViewController
<MPMediaPickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *pickSongButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UIButton *wrongButton;
@property (weak, nonatomic) IBOutlet UITextView *lyricalTextView;

@property (nonatomic, strong) NSURL *songURL;
@end
