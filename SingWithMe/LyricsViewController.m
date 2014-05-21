//
//  LyricsViewController.m
//  SingWithMe
//
//  Created by David Zhang on 2014-05-19.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "LyricsViewController.h"
#import "SyncViewController.h"

#define LYRICSTART  @"<!-- start of lyrics -->"
#define LYRICEND    @"<!-- end of lyrics -->"

@implementation LyricsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Pick A Song
- (IBAction)pickSong:(id)sender {
    /* Create a Media Picker Menu and set it as present view */
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    [picker setDelegate:self];
    [picker setAllowsPickingMultipleItems: NO];
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void) mediaPicker:(MPMediaPickerController *)mediaPicker
   didPickMediaItems:(MPMediaItemCollection *)collection
{
    /* Remove media picker view */
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    /* Grab first song and load */
    MPMediaItem *item = [[collection items] objectAtIndex:0];
    self.songURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    [self findLyricalDataWith:item];
}

- (void) mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    /* Remove media picker view */
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Find Lyrics
- (void) findLyricalDataWith:(MPMediaItem *)item
{

    // Find title + artist and remove white spaces
    NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString* title = [[[[item valueForProperty:MPMediaItemPropertyTitle] lowercaseString]
                         componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];
    
    NSString* artist = [[[[item valueForProperty:MPMediaItemPropertyArtist] lowercaseString]
                         componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];

    
    NSString *testString = [NSString stringWithFormat:@"http://www.azlyrics.com/lyrics/%@/%@.html",artist,title];
    NSLog(@"Trying %@", testString);
    NSURL *testURL = [NSURL URLWithString:testString];
    NSError *error;
    
    // TODO: if the language is not eng, have to use a different encoding
    // HANDLE IT
    NSString *testHTML = [NSString stringWithContentsOfURL:testURL
                                                  encoding:NSASCIIStringEncoding
                                                     error:&error];
    
    // TODO: if testHTML == 0 char long, redirect happened and the link was bad
    // HANDLE IT
    if ( testHTML.length != 0 ) {
        // Parse and proceed
        self.lyricalTextView.text = [self parseLyricsFromHTML:testHTML];
        self.rightButton.hidden = NO;
        self.wrongButton.hidden = NO;
    }
}

- (NSString *) parseLyricsFromHTML:(NSString *)html
{
    NSRange start = [html rangeOfString:LYRICSTART];
    NSRange end = [html rangeOfString:LYRICEND];

    NSRange range;
    range.location = start.location + start.length;
    range.length = end.location - start.location - end.length - 2;  // 2 is the magic number
    
    NSString *parsed = [[[[html substringWithRange:range]
                         stringByReplacingOccurrencesOfString:@"<br />" withString:@""]
                         stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"] substringFromIndex:2];
    
    return parsed;
}
// TODO: Good place to do data collection for metrics
//- (IBAction)right:(id)sender {
//    
//}

//- (IBAction)wrong:(id)sender {
//    // TODO: Implement this
//    // This should allow for manual editing as well as just try again
//}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"transitionSyncVC"]) {
        // send over lyrics for syncing
        SyncViewController *destViewController = segue.destinationViewController;
        destViewController.lyrics = self.lyricalTextView.text;
        destViewController.songURL = self.songURL;
    }
}


@end
