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

            [self.audioFileDelegate audioFile:self
                                    readAudio:_floatBuffers
                               withBufferSize:frames
                         withNumberOfChannels:_clientFormat.mChannelsPerFrame];
            
            // Cancel out vocals 
            if ( phase ) {
                // Use _floatBuffers to perform phase cancellation
                // TODO: Maybe figure out how to only take vocals (since we can cancel might be a way to do opposite)
                for (int i = 0; i < frames; i++) {
                    _floatBuffers[0][i] = (_floatBuffers[0][i] - _floatBuffers[1][i])/2;
                    _floatBuffers[1][i] = _floatBuffers[0][i];
                }
                AEFloatConverterFromFloat(converter, _floatBuffers, audioBufferList, frames);
            }
        }
    }
}
@end
