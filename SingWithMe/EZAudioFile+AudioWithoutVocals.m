//
//  EZAudioFile+AudioWithoutVocals.m
//  SingWithMe
//
//  Created by David Zhang on 2014-04-15.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "EZAudioFile+AudioWithoutVocals.h"

@implementation EZAudioFile (AudioWithoutVocals)
- (void) output:(EZOutput *)output
     readFrames:(UInt32)frames
audioBufferList:(AudioBufferList *)audioBufferList
     bufferSize:(UInt32 *)bufferSize
            eof:(BOOL *)eof
    phaseVocals:(BOOL)phase
{
    [EZAudio checkResult:ExtAudioFileRead(_audioFile,
                                          &frames,
                                          audioBufferList)
               operation:"Failed to read audio data from audio file"];
    *bufferSize = audioBufferList->mBuffers[0].mDataByteSize/sizeof(AudioUnitSampleType);
    *eof = frames == 0;
    _frameIndex += frames;
    
    if( self.audioFileDelegate ){
        if( [self.audioFileDelegate respondsToSelector:@selector(audioFile:updatedPosition:)] ){
            [self.audioFileDelegate audioFile:self
                              updatedPosition:_frameIndex];
        }
        
        if( [self.audioFileDelegate respondsToSelector:@selector(audioFile:readAudio:withBufferSize:withNumberOfChannels:)] ){
            AEFloatConverter *converter = [self getFloatConverter];
            AEFloatConverterToFloat(converter,audioBufferList,_floatBuffers,frames);
            
            // Send data
            [self.audioFileDelegate audioFile:self
                                    readAudio:_floatBuffers
                               withBufferSize:frames
                         withNumberOfChannels:_clientFormat.mChannelsPerFrame];
            
            // Perform phase
            if ( phase ) {
                // TODO: Test if this method still affects output graph if vocals are phased out
                // (Should not do that)
                float **copiedBuffers = (float **)malloc(2);
                copiedBuffers[0] = (float *)malloc(1024*sizeof(float));
                copiedBuffers[1] = (float *)malloc(1024*sizeof(float));
                memcpy(copiedBuffers[0], _floatBuffers[0], frames * sizeof(float));
                memcpy(copiedBuffers[1], _floatBuffers[1], frames * sizeof(float));
                
                float *left = copiedBuffers[0];
                float *right = copiedBuffers[1];
                for (int i = 0; i < frames; i++) {
                    left[i] = (left[i] - right[i])/2;
                    right[i] = left[i];
                }
                AEFloatConverterFromFloat(converter, copiedBuffers, audioBufferList, frames);
            }

        }
    }
}
@end
