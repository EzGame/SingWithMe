//
//  EZAudioFile+AudioWithoutVocals.h
//  SingWithMe
//
//  Created by David Zhang on 2014-04-15.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "EZAudio.h"
#import "EZAudioFile.h"

@interface EZAudioFile (AudioWithoutVocals)
- (void) readFrames:(UInt32)frames audioBufferList:(AudioBufferList *)audioBufferList bufferSize:(UInt32 *)bufferSize eof:(BOOL *)eof phaseVocals:(BOOL)vocals;
@end
