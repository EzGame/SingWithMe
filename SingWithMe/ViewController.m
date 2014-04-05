//
//  ViewController.m
//  SingWithMe
//
//  Created by David Zhang on 2014-04-05.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "ViewController.h"

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
    [self.audioPlayer setNumberOfLoops:-1];
    
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
@end
