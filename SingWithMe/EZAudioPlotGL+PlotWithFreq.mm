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
- (float) freqUpdateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize
{
    EZAudioPlotGLKViewController *glViewController = [self getGLViewController];
    return [glViewController freqUpdateBuffer:buffer
                               withBufferSize:bufferSize];
}
@end

@implementation EZAudioPlotGLKViewController (PlotWithFreq)
- (float) freqUpdateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize
{
    // Make sure the update render loop is active
    if( self.paused ) self.paused = NO;
    
    // Make sure we are updating the buffers on the correct gl context.
    EAGLContext.currentContext = self.context;
    
    // Draw based on plot type
    float freqRet = 0;
    switch(self.plotType) {
        case EZPlotTypeBuffer:
            freqRet = [self freqUpdateBufferPlotWithAudioReceived:buffer
                                                   withBufferSize:bufferSize];
            break;
        case EZPlotTypeRolling:
            freqRet = [self freqUpdateRollingPlotWithAudioReceived:buffer
                                                    withBufferSize:bufferSize];
            break;
        default:
            break;
    }
    return freqRet;
}

- (float) freqUpdateBufferPlotWithAudioReceived:(float *)buffer
                                 withBufferSize:(UInt32)bufferSize
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

- (float) freqUpdateRollingPlotWithAudioReceived:(float *)buffer
                                  withBufferSize:(UInt32)bufferSize
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
    float freq = [EZAudio freqUpdateScrollHistory:&_scrollHistory
                                       withLength:_scrollHistoryLength
                                          atIndex:&_scrollHistoryIndex
                                       withBuffer:buffer
                                   withBufferSize:bufferSize
                             isResolutionChanging:&_changingHistorySize];
    
    // Fill in graph data
    [EZAudioPlotGL fillGraph:graph
               withGraphSize:_rollingPlotGraphSize
              forDrawingType:self.drawingType
                  withBuffer:_scrollHistory
              withBufferSize:_scrollHistoryLength
                    withGain:self.gain];
    
    // Update the drawing
    if( !_hasRollingPlotData ){
        glBufferData( GL_ARRAY_BUFFER, sizeof(graph) , graph, GL_STREAM_DRAW );
        _hasRollingPlotData = YES;
    }
    else {
        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(graph), graph);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    return freq;
}

@end

@implementation EZAudio (PlotWithFreq)
+ (float) freqUpdateScrollHistory:(float **)scrollHistory
                       withLength:(int)scrollHistoryLength
                          atIndex:(int*)index
                       withBuffer:(float *)buffer
                   withBufferSize:(int)bufferSize
             isResolutionChanging:(BOOL*)isChanging
{
    //
    size_t floatByteSize = sizeof(float);
    
    //
    if( *scrollHistory == NULL ){
        // Create the history buffer
        *scrollHistory = (float*)calloc(kEZAudioPlotMaxHistoryBufferLength,floatByteSize);
    }
    
    //
    if( !*isChanging ){
        float freq = findFrequency(buffer, bufferSize, 44100);
        if( *index < scrollHistoryLength ){
            float *hist = *scrollHistory;
            hist[*index] = freq;
            (*index)++;
        }
        else {
            [EZAudio appendValue:freq
                 toScrollHistory:*scrollHistory
           withScrollHistorySize:scrollHistoryLength];
        }
        return freq;
    }
    
    // TODO: temp
    NSAssert(true, @"Break point for freq update scroll history");
    return 0;
}
@end