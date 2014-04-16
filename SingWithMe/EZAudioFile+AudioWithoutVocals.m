//
//  EZAudioFile+AudioWithoutVocals.m
//  SingWithMe
//
//  Created by David Zhang on 2014-04-15.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "EZAudioFile+AudioWithoutVocals.h"

@implementation EZAudioFile (AudioWithoutVocals)
- (void) readFrames:(UInt32)frames audioBufferList:(AudioBufferList *)audioBufferList bufferSize:(UInt32 *)bufferSize eof:(BOOL *)eof phaseVocals:(BOOL)phase
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
            
            // Cancel out vocals
            // TODO: Make this work
            // It seems that audioBufferList is not created with two channels in mind, yet it is formated to two channels
            // in _floatBuffers. The audio seems to be interleaved, although the previous command was supposed to undo
            // that.
            if ( phase ) {
                float *finalBuffer = (float *)malloc(frames*2*sizeof(float));
                for (int i = 0; i < frames*2; i++) {
                    finalBuffer[i] = (_floatBuffers[0][i] - _floatBuffers[1][i])/2;
                }
                
                memcpy(audioBufferList->mBuffers[0].mData, finalBuffer, frames*sizeof(float));
                memcpy(audioBufferList->mBuffers[1].mData, finalBuffer, frames*sizeof(float));
                free(finalBuffer);
            }
            
            [self.audioFileDelegate audioFile:self
                                    readAudio:_floatBuffers
                               withBufferSize:frames
                         withNumberOfChannels:_clientFormat.mChannelsPerFrame];
        }
    }
}
@end
