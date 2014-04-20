//
//  EZAudioPlotGL+PlotWithFreq.m
//  SingWithMe
//
//  Created by David Zhang on 2014-04-14.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "EZAudioPlotGL+PlotWithFreq.h"
#import "FFTHelper.h"

@implementation EZAudioPlotGL (PlotWithFreq)
- (float) updateBuffer:(float *)buffer
        withBufferSize:(UInt32)bufferSize
         andSampleRate:(int)sampleRate
                   RMS:(BOOL)isRMS
{
    EZAudioPlotGLKViewController *glViewController = [self getGLViewController];
    return [glViewController updateBuffer:buffer
                           withBufferSize:bufferSize
                            andSampleRate:sampleRate
                                      RMS:isRMS];
}
@end

@implementation EZAudioPlotGLKViewController (PlotWithFreq)

- (float) updateBuffer:(float *)buffer
        withBufferSize:(UInt32)bufferSize
         andSampleRate:(int)sampleRate
                   RMS:(BOOL)isRMS
{
    // Make sure the update render loop is active
    if( self.paused ) self.paused = NO;
    
    // Make sure we are updating the buffers on the correct gl context.
    EAGLContext.currentContext = self.context;
    
    // Draw based on plot type
    float ret = 0;
    switch(self.plotType) {
        case EZPlotTypeBuffer:
            ret = [self freqUpdateBufferPlotWithAudioReceived:buffer
                                               withBufferSize:bufferSize
                                                andSampleRate:sampleRate];
            break;
        case EZPlotTypeRolling:
            ret = [self updateRollingPlotWithAudioReceived:buffer
                                            withBufferSize:bufferSize
                                             andSampleRate:sampleRate
                                                       RMS:isRMS];
            break;
        default:
            break;
    }
    return ret;
}

- (float) freqUpdateBufferPlotWithAudioReceived:(float *)buffer
                                 withBufferSize:(UInt32)bufferSize
                                  andSampleRate:(int)sampleRate
{
    glBindBuffer(GL_ARRAY_BUFFER, _bufferPlotVBO);
    
    // If starting with a VBO of half of our max size make sure we initialize it to anticipate
    // a filled graph (which needs 2 * bufferSize) to allocate its resources properly
    if( !_hasBufferPlotData && self.drawingType == EZAudioPlotGLDrawTypeLineStrip ){
        EZAudioPlotGLPoint maxGraph[2*bufferSize];
        glBufferData(GL_ARRAY_BUFFER, sizeof(maxGraph), maxGraph, GL_STREAM_DRAW );
        _hasBufferPlotData = YES;
    }
    
    // Setup the buffer plot's graph size
    _bufferPlotGraphSize = [EZAudioPlotGL graphSizeForDrawingType:self.drawingType
                                                   withBufferSize:bufferSize];
    
    // Setup the graph
    EZAudioPlotGLPoint graph[_bufferPlotGraphSize];
    
    // Fill in graph data
    [EZAudioPlotGL fillGraph:graph
               withGraphSize:_bufferPlotGraphSize
              forDrawingType:self.drawingType
                  withBuffer:buffer
              withBufferSize:bufferSize
                    withGain:self.gain];
    
    if( !_hasBufferPlotData ){
        glBufferData( GL_ARRAY_BUFFER, sizeof(graph), graph, GL_STREAM_DRAW );
        _hasBufferPlotData = YES;
    }
    else {
        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(graph), graph);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    return 0;
}

- (float) updateRollingPlotWithAudioReceived:(float *)buffer
                              withBufferSize:(UInt32)bufferSize
                               andSampleRate:(int)sampleRate
                                         RMS:(BOOL)isRMS

{
    glBindBuffer(GL_ARRAY_BUFFER, _rollingPlotVBO);
    
    // If starting with a VBO of half of our max size make sure we initialize it to anticipate
    // a filled graph (which needs 2 * bufferSize) to allocate its resources properly
    if( !_hasRollingPlotData ){
        EZAudioPlotGLPoint maxGraph[2*kEZAudioPlotMaxHistoryBufferLength];
        glBufferData( GL_ARRAY_BUFFER, sizeof(maxGraph), maxGraph, GL_STREAM_DRAW );
        _hasRollingPlotData = YES;
    }
    
    // Setup the plot
    _rollingPlotGraphSize = [EZAudioPlotGL graphSizeForDrawingType:self.drawingType
                                                    withBufferSize:_scrollHistoryLength];
    
    // Fill the graph with data
    EZAudioPlotGLPoint graph[_rollingPlotGraphSize];
    
    // Update the scroll history datasource
    float value = [EZAudio updateScrollHistory:&_scrollHistory
                                    withLength:_scrollHistoryLength
                                       atIndex:&_scrollHistoryIndex
                                    withBuffer:buffer
                                withBufferSize:bufferSize
                          isResolutionChanging:&_changingHistorySize
                                 andSampleRate:sampleRate
                                           RMS:isRMS];
    
    // Fill in graph data
    [EZAudioPlotGL fillGraph:graph
               withGraphSize:_rollingPlotGraphSize
              forDrawingType:self.drawingType
                  withBuffer:_scrollHistory
              withBufferSize:_scrollHistoryLength
                    withGain:(isRMS) ? self.gain : self.gain * 0.002];
    
    // Update the drawing
    if( !_hasRollingPlotData ){
        glBufferData( GL_ARRAY_BUFFER, sizeof(graph) , graph, GL_STREAM_DRAW );
        _hasRollingPlotData = YES;
    }
    else {
        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(graph), graph);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    return value;
}

@end

@implementation EZAudio (PlotWithFreq)
+ (float) updateScrollHistory:(float **)scrollHistory
                   withLength:(int)scrollHistoryLength
                      atIndex:(int*)index
                   withBuffer:(float *)buffer
               withBufferSize:(int)bufferSize
         isResolutionChanging:(BOOL*)isChanging
                andSampleRate:(int)sampleRate
                          RMS:(BOOL)isRMS;
{
    size_t floatByteSize = sizeof(float);
    
    // Create the history buffer if it doesnt exist
    if( *scrollHistory == NULL ){
        *scrollHistory = (float*)calloc(kEZAudioPlotMaxHistoryBufferLength,floatByteSize);
    }
    
    // Find the frequency to return
    if( !*isChanging ){
        // TODO: Make this work
        // We find some sort of frequency at the moment, but it seems that we need to do some sort of windowing
        // to the set of data retrieved as the short burts of high/low frequencies are very noisy for the data.
        // Also need to filter out the instrumentals and find a way to normalize these values appropriately.
        float value = (isRMS) ? [self RMS:buffer length:bufferSize] : findFrequency(buffer, bufferSize, sampleRate);
        if( *index < scrollHistoryLength ){
            float *hist = *scrollHistory;
            hist[*index] = value;
            (*index)++;
        } else {
            [EZAudio appendValue:value
                 toScrollHistory:*scrollHistory
           withScrollHistorySize:scrollHistoryLength];
        }
        return value;
    }
    return 0;
}
@end