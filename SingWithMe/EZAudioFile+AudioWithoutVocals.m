//
//  EZAudioFile+AudioWithoutVocals.m
//  SingWithMe
//
//  Created by David Zhang on 2014-04-15.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "EZAudioFile+AudioWithoutVocals.h"

@implementation EZAudioFile (AudioWithoutVocals)
- (void) readFrames:(UInt32)frames audioBufferList:(AudioBufferList *)audioBufferList bufferSize:(UInt32 *)bufferSize eof:(BOOL *)eof phaseVocals:(BOOL)vocals
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
            if ( !vocals ) {
                int32_t bytesToCopy = audioBufferList->mBuffers[0].mDataByteSize;
                AudioSampleType *left  = (AudioSampleType*)audioBufferList->mBuffers[0].mData;
                AudioSampleType *right = (AudioSampleType*)audioBufferList->mBuffers[1].mData;
                
                // We remove vocals by cancelling out the centered vocal waveforms
                for (int i = 0; i < bytesToCopy; i++) {
                    left[i] = (left[i] - right[i])/2;
                }
                
                // Copy left into right side
                memcpy( left,  right, bytesToCopy );
            }
        }
        
    }
}
@end
