//
//  ViewController.m
//  SingWithMe
//
//  Created by David Zhang on 2014-04-05.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "ViewController.h"
#import "FFTHelper.h"



@interface ViewController ()
@end

@implementation ViewController
- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Play back controls
-(void) playSongWithURL:(NSURL *)url
{
    // Configure a new audioPlayer
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.audioPlayer setNumberOfLoops:0];
    
    // Play
    [self.audioPlayer play];
}

#pragma mark - Misc
/* Play Button Touch Down */
- (IBAction) playButtonTouch:(id)sender
{
#if TARGET_IPHONE_SIMULATOR
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Media picker doesn't work in the simulator, please run this app on a device." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
#else
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    [picker setDelegate:self];
    [picker setAllowsPickingMultipleItems: NO];
    [self presentViewController:picker animated:YES completion:NULL];
#endif
}

#pragma mark - Media Picker
/* Media Picker View - Media Selected Callback */
- (void) mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)collection
{
    // Remove Media picker view
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    // Grab first item
    MPMediaItem *item = [[collection items] objectAtIndex:0];
    
    // Set now playing label
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    self.playLabel.text = title;
    
    // Play song with URL
    NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    [self playSongWithURL:url];
}

/* Cancel out of Media Picker View */
- (void) mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - CoreAudio stuff
- (void) coreAudioStuff:(NSURL *)url
{
    // Get asset reader settings for a Linear PCM read
	NSDictionary *audioReadOptions = [NSDictionary
                                      dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, nil];
    
    // Load song asset into reader
    NSError *error = nil;
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:url options:audioReadOptions];
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    if ( error ) {
        NSLog (@"   playSongWithURL: error %@", error);
		return;
    }
	
    // Create an output and push values into it
	AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput
                                              assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                                              audioSettings:audioReadOptions];
	if ( ![assetReader canAddOutput: assetReaderOutput]) {
		NSLog (@"   playSongWithURL: error can't store output");
		return;
	}
	[assetReader addOutput: assetReaderOutput];
    
//    // Clean up and reinit our audio out buffer
//    TPCircularBufferCleanup(_audioOutBuffer);
//    TPCircularBufferInit(_audioOutBuffer, 1000000);
    
    // Read a buffer and find format
    [assetReader startReading];
    CMSampleBufferRef nextSampleBuffer = [assetReaderOutput copyNextSampleBuffer];
    
    // Main read loop
    while ( nextSampleBuffer != nil ) {
        // Get Audio buffer list and number of samples
        AudioBufferList audioBufferList;
        CMItemCount numSamplesInBuffer = CMSampleBufferGetNumSamples(nextSampleBuffer);
        size_t bufferListSizeNeededOut;
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(nextSampleBuffer,
                                                                &bufferListSizeNeededOut,
                                                                &audioBufferList,
                                                                sizeof(audioBufferList),
                                                                kCFAllocatorSystemDefault,
                                                                kCFAllocatorSystemDefault,
                                                                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                nil);
        
        // FFT that shit
        for (int bufferCount = 0; bufferCount < audioBufferList.mNumberBuffers; bufferCount++) {
            SInt16* samples = (SInt16 *)audioBufferList.mBuffers[bufferCount].mData;
            float freq = findFrequency(samples, numSamplesInBuffer);
            self.freqLabel.text = [NSString stringWithFormat:@"freq: %f", freq];
            NSLog(@" freq is %f", freq);
        }
        
        // Add the buffer list into audio out
//        TPCircularBufferCopyAudioBufferList(_audioOutBuffer,
//                                            &audioBufferList,
//                                            nil,
//                                            kTPCircularBufferCopyAll,
//                                            nil);
        
        
        // Go next
        CFRelease(nextSampleBuffer);
        nextSampleBuffer = [assetReaderOutput copyNextSampleBuffer];
    }
}
@end
