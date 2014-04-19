//
//  EZAudioPlotGL+PlotWithFreq.h
//  SingWithMe
//
//  Created by David Zhang on 2014-04-14.
//  Copyright (c) 2014 EzGame. All rights reserved.
//
//  The catagory PlotWithFreq is an extension of the EZAudio
//  classes to provide a plot of frequencies instead of
//  power. The function calls stack also returns the frequency
//  of the buffer being analyzed for comparison later on.
//

#import "EZAudio.h"
#import "EZAudioPlotGL.h"
#import "EZAudioPlotGLKViewController.h"

@interface EZAudioPlotGL (PlotWithFreq)
- (float) updateBuffer:(float *)buffer
        withBufferSize:(UInt32)bufferSize
         andSampleRate:(int)sampleRate
                   RMS:(BOOL)isRMS;

@end

@interface EZAudioPlotGLKViewController (PlotWithFreq)
- (float) updateBuffer:(float *)buffer
        withBufferSize:(UInt32)bufferSize
         andSampleRate:(int)sampleRate
                   RMS:(BOOL)isRMS;
@end

@interface EZAudio (PlotWithFreq)
+ (float) updateScrollHistory:(float **)scrollHistory
                   withLength:(int)scrollHistoryLength
                      atIndex:(int*)index
                   withBuffer:(float *)buffer
               withBufferSize:(int)bufferSize
         isResolutionChanging:(BOOL*)isChanging
                andSampleRate:(int)sampleRate
                          RMS:(BOOL)isRMS;
@end