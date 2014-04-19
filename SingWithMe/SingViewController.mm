//
//  ViewController.m
//  SingWithMe
//
//  Created by David Zhang on 2014-04-05.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "SingViewController.h"

@interface SingViewController ()
@property (nonatomic, strong) EZAudioFile   *currentAudioFile;
@property (nonatomic, strong) EZMicrophone  *currentMic;
@property (nonatomic, strong) EZRecorder    *currentRecording;
@property (nonatomic, strong) SingModel     *model;
@property (nonatomic)         int           currentSampleRate;
@property (nonatomic)         BOOL          eof;
@end

@implementation SingViewController
- (void) viewDidLoad
{
    [super viewDidLoad];
    
    /* Create our model */
    self.model = [[SingModel alloc] init];
    
    /* Create audio feed plot */
    self.currentAudioPlot.color = [UIColor blueColor];
    self.currentAudioPlot.plotType = EZPlotTypeRolling;
    self.currentAudioPlot.shouldFill = YES;
    self.currentAudioPlot.shouldMirror = NO;
    
    /* Create mic feed plot */
    self.currentMicPlot.color = [UIColor greenColor];
    self.currentMicPlot.plotType = EZPlotTypeRolling;
    self.currentMicPlot.shouldFill = YES;
    self.currentMicPlot.shouldMirror = NO;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadSongWithURL:(NSURL *)aURL
{
    /* Load song URL */
    [[EZOutput sharedOutput] stopPlayback];
    
    self.currentAudioFile = [EZAudioFile audioFileWithURL:aURL andDelegate:self];
    self.currentSampleRate = [self.currentAudioFile fileFormat].mSampleRate;
    self.eof = NO;

    [[EZOutput sharedOutput] setAudioStreamBasicDescription:self.currentAudioFile.clientFormat];
    
    /* Load mic */
    self.currentMic = [EZMicrophone microphoneWithDelegate:self];
}





#pragma mark - IBActions
- (IBAction) playToggle:(id)sender
{
    /* Play */
    if( ![[EZOutput sharedOutput] isPlaying] ){
        [EZOutput sharedOutput].outputDataSource = self;
        [[EZOutput sharedOutput] startPlayback];
    }
    /* Pause */
    else {
        [EZOutput sharedOutput].outputDataSource = nil;
        [[EZOutput sharedOutput] stopPlayback];
    }
    
    /* Record */
    if (!self.currentMic.microphoneOn) {
        [self.currentMic startFetchingAudio];
        self.noteDebugLabel.text = @"Mic ON";
    }
    /* Pause */
    else {
        [self.currentMic stopFetchingAudio];
        self.noteDebugLabel.text = @"Mic OFF";
    }
}

- (IBAction) pickSong:(id)sender
{
    /* We toggle the playback so that it pauses mic automatically */
    if ( [[EZOutput sharedOutput] isPlaying] )
        [self playToggle:nil];
    
    /* Create a Media Picker Menu and set it as present view */
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    [picker setDelegate:self];
    [picker setAllowsPickingMultipleItems: NO];
    [self presentViewController:picker animated:YES completion:NULL];
}





#pragma mark - MPMediaPickerControllerDelegate
- (void) mediaPicker:(MPMediaPickerController *)mediaPicker
   didPickMediaItems:(MPMediaItemCollection *)collection
{
    /* Remove media picker view */
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    /* Grab first song and load */
    MPMediaItem *item = [[collection items] objectAtIndex:0];
    self.currentSongLabel.text = [item valueForProperty:MPMediaItemPropertyTitle];
    [self loadSongWithURL:[item valueForProperty:MPMediaItemPropertyAssetURL]];
}

- (void) mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    /* Remove media picker view */
    [self dismissViewControllerAnimated:YES completion:NULL];
}





#pragma mark - EZAudioFileDelegate
- (void) audioFile:(EZAudioFile *)audioFile readAudio:(float **)buffer withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels
{
    /* GCD block to send buffer data into plot */
    dispatch_async(dispatch_get_main_queue(), ^{
        if( [EZOutput sharedOutput].isPlaying ){
            float value = [self.currentAudioPlot updateBuffer:buffer[0]
                                               withBufferSize:bufferSize
                                                andSampleRate:self.currentSampleRate
                                                          RMS:NO];
            self.noteDebugLabel.text = [NSString stringWithFormat:@"%f @ %d", value, self.currentSampleRate];
        }
    });
}

- (void) audioFile:(EZAudioFile *)audioFile
   updatedPosition:(SInt64)framePosition
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if( !self.framePositionSlider.touchInside ){
//            self.framePositionSlider.value = (float)framePosition;
//        }
//    });
}





#pragma mark - EZMicrophoneDeletgate 
#warning Thread Safety
- (void) microphone:(EZMicrophone *)microphone hasAudioReceived:(float **)buffer withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels
{
    /* GCD block to send buffer data into plot */
    dispatch_async(dispatch_get_main_queue(),^{
        float value = [self.currentMicPlot updateBuffer:buffer[0]
                                         withBufferSize:bufferSize
                                          andSampleRate:self.currentSampleRate
                                                    RMS:NO];
    });
}

-(void) microphone:(EZMicrophone *)microphone hasAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription
{
    /* Set recorder with ASBD with microphone format */
    self.currentRecording = [EZRecorder recorderWithDestinationURL:[self.model testFilePathURL]
                                                   andSourceFormat:audioStreamBasicDescription];
}

-(void)microphone:(EZMicrophone *)microphone hasBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels
{
    /* Append audio data from microphone to recording */
    if( self.currentRecording ) {
        [self.currentRecording appendDataFromBufferList:bufferList
                                         withBufferSize:bufferSize];
    }
}





#pragma mark - EZOutputDataSource
- (void) output:(EZOutput *)output shouldFillAudioBufferList:(AudioBufferList *)audioBufferList withNumberOfFrames:(UInt32)frames
{
    if( self.currentAudioFile ) {
        UInt32 bufferSize;
        [self.currentAudioFile output:output
                           readFrames:frames
                      audioBufferList:audioBufferList
                           bufferSize:&bufferSize
                                  eof:&_eof
                          phaseVocals:self.phaseCancel.on];
    }
}
@end