//
//  ViewController.m
//  SingWithMe
//
//  Created by David Zhang on 2014-04-05.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "ViewController.h"
#import "FFTHelper.h"

/// max value from vector with value index (using Accelerate Framework)
static Float32 vectorMaxValueACC32_index(Float32 *vector, unsigned long size, long step, unsigned long *outIndex) {
    Float32 maxVal;
    vDSP_maxvi(vector, step, &maxVal, outIndex, size);
    return maxVal;
}

/// caculates HZ value for specified index from a FFT bins vector
static Float32 frequencyHerzValue(long frequencyIndex, long fftVectorSize, Float32 nyquistFrequency ) {
    return ((Float32)frequencyIndex/(Float32)fftVectorSize) * nyquistFrequency;
}

///returns HZ of the strongest frequency.
static Float32 strongestFrequencyHZ(Float32 *buffer, FFTHelperRef *fftHelper, UInt32 frameSize, Float32 *freqValue) {
    Float32 *fftData = computeFFT(fftHelper, buffer, frameSize);
    fftData[0] = 0.0;
    unsigned long length = frameSize/2.0;
    Float32 max = 0;
    unsigned long maxIndex = 0;
    max = vectorMaxValueACC32_index(fftData, length, 1, &maxIndex);
    if (freqValue!=NULL) { *freqValue = max; }
    Float32 HZ = frequencyHerzValue(maxIndex, length, 22050);
    return HZ;
}



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

//- (float) performAcceleratedFastFourierTransForAudioBuffer:(AudioBufferList)ioData
//{
//    NSUInteger * sampleIn = (NSUInteger *)ioData.mBuffers[0].mData;
//    for (int i = 0; i < nOver2; i++) {
//        double multiplier = 0.5 * (1 - cos(2*M_PI*i/nOver2-1));
//        A.realp[i] = multiplier * sampleIn[i];
//        A.imagp[i] = 0;
//    }
//    
//    memset(ioData.mBuffers[0].mData, 0, ioData.mBuffers[0].mDataByteSize);
//    vDSP_fft_zrip(setupReal, &A, stride, log2n, FFT_FORWARD);
//    
//    vDSP_zvmags(&A, 1, A.realp, 1, nOver2);
//    
//    scale = (float) 1.0 / (2 * n);
//    
//    vDSP_vsmul(A.realp, 1, &scale, A.realp, 1, nOver2);
//    vDSP_vsmul(A.imagp, 1, &scale, A.imagp, 1, nOver2);
//    
//    vDSP_ztoc(&A, 1, (COMPLEX *)obtainedReal, 2, nOver2);
//    
//    int peakIndex = 0;
//    for (size_t i=1; i < nOver2-1; ++i) {
//        if ((obtainedReal[i] > obtainedReal[i-1]) && (obtainedReal[i] > obtainedReal[i+1]))
//        {
//            peakIndex = i;
//            break;
//        }
//    }
//    
//    //here i don't know how to calculate frequency with my data
//    float frequency = obtainedReal[peakIndex-1] / 44100 / n;
//    
//    vDSP_destroy_fftsetup(setupReal);
//    free(obtainedReal);
//    free(A.realp);
//    free(A.imagp);
//    
//    return frequency;  
//}

#pragma mark - Play back controls
-(void) playSongWithURL:(NSURL *)url
{
    // Configure a new audioPlayer
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.audioPlayer setNumberOfLoops:0];
    
    // Play
    [self.audioPlayer play];
    
    
    // Get asset reader settings for a Linear PCM read
	NSDictionary *audioReadOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, nil];
    
    // Load song asset into reader
    NSError *error = nil;
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:url options:audioReadOptions];
    NSLog(@"Total asset time %f", CMTimeGetSeconds(songAsset.duration));
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    if ( error ) {
        NSLog (@"   playSongWithURL: error %@", error);
		return;
    }
	
    // Create an output and push values into it
	AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput
                                               assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                                              audioSettings: audioReadOptions];
	if ( ![assetReader canAddOutput: assetReaderOutput]) {
		NSLog (@"   playSongWithURL: error can't store output");
		return;
	}
	[assetReader addOutput: assetReaderOutput];
    [assetReader startReading];
    
    // Read a buffer and find format
    CMSampleBufferRef nextSampleBuffer = [assetReaderOutput copyNextSampleBuffer];
    
    // Main read loop
    while ( nextSampleBuffer != nil ) {
        
        // Get stuff lol
        CMItemCount numSamples = CMSampleBufferGetNumSamples(nextSampleBuffer);
        CMBlockBufferRef audioBuffer = CMSampleBufferGetDataBuffer(nextSampleBuffer);
        size_t lengthAtOffset;
        size_t totalLength;
        char *samples;
        int ret = CMBlockBufferGetDataPointer(audioBuffer, 0, &lengthAtOffset, &totalLength, &samples);
        if ( ret != 0 ) {
            NSLog(@"    playSongWIthURL: error with get data");
            break;
        }
        
        // Audio buffer list
        AudioBufferList audioBufferList;// = AAudioBufferList::Create(currentInputASBD.mChannelsPerFrame);
        //CMBlockBufferRef blockBufferOut = nil;
        size_t bufferListSizeNeededOut;
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(nextSampleBuffer,
                                                                &bufferListSizeNeededOut,
                                                                &audioBufferList,
                                                                sizeof(audioBufferList),
                                                                kCFAllocatorSystemDefault,
                                                                kCFAllocatorSystemDefault,
                                                                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                &audioBuffer);
        
        NSLog(@" num samples %ld", numSamples);
        for (int bufferCount = 0; bufferCount < audioBufferList.mNumberBuffers; bufferCount++) {
            SInt16* samples = (SInt16 *)audioBufferList.mBuffers[bufferCount].mData;
            for (int i = 0; i < numSamples; i++) {
                
                // amplitude for the sample is samples[i], assuming you have linear pcm to start with
            }
        }
        
        CFRelease(nextSampleBuffer);
        nextSampleBuffer = [assetReaderOutput copyNextSampleBuffer];
    }

//	NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//	NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
//	NSString *exportPath = [documentsDirectoryPath stringByAppendingPathComponent:EXPORT_NAME];
//	if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
//		[[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
//	}
//	NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
//	__block AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:exportURL
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
