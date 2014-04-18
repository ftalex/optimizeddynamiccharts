//
//  NCISimpleGridView.m
//  NCIChart
//
//  Created by Ira on 12/22/13.
//  Copyright (c) 2013 FlowForwarding.Org. All rights reserved.
//

#import "NCISimpleGridView.h"

@interface NCISimpleGridView(){

}

@end

@implementation NCISimpleGridView


- (id)initWithGraph:(NCISimpleGraphView *) ncigraph{
    self = [self initWithFrame:CGRectZero];
    if (self){
        self.graph = ncigraph;
        [self setBgColor];
    }
    return self;
}

- (void)setBgColor{
    if (self.graph.chart.nciGridColor){
        self.backgroundColor = self.graph.chart.nciGridColor;
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}

- (void)drawRect:(CGRect)rect
{
    [self setBgColor];
    [self drawGraphLine:[self getFirstLast]];
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    [self setHorizontalGrid:currentContext];
    [self setVerticalGrid:currentContext];
    [self setBoundaryVertical:currentContext];
    [self setBoundaryHorizontal:currentContext];
}

//pragma draw grid
- (void)setVerticalGrid:(CGContextRef) currentContext{
    [self.graph.chart.nciGridVertical setUpLine:currentContext];
    float labelWidth = 0;
    if (_graph.chart.xAxis.labels.count > 0){
         labelWidth = ((UILabel *)_graph.chart.xAxis.labels[0]).frame.size.width;
    }
    for (UILabel *xLabel in _graph.chart.xAxis.labels){
        CGContextMoveToPoint(currentContext, xLabel.frame.origin.x - _graph.chart.nciGridLeftMargin
                             + labelWidth/2, xLabel.frame.origin.y);
        CGContextAddLineToPoint(currentContext, xLabel.frame.origin.x - _graph.chart.nciGridLeftMargin
                                + labelWidth/2, 0);
    }
    CGContextStrokePath(currentContext);
}

- (void)setHorizontalGrid:(CGContextRef) currentContext{
    [self.graph.chart.nciGridHorizontal setUpLine:currentContext];
    float labelHeight = 0;
    if (_graph.chart.yAxis.labels.count > 0){
        labelHeight = ((UILabel *)_graph.chart.yAxis.labels[0]).frame.size.height;
    }
    for (UILabel *yLabel in _graph.chart.yAxis.labels){
        CGContextMoveToPoint(currentContext, yLabel.frame.origin.x, yLabel.frame.origin.y + labelHeight/2);
        CGContextAddLineToPoint(currentContext, self.frame.size.width, yLabel.frame.origin.y + labelHeight/2);
    }
    CGContextStrokePath(currentContext);
}

- (void)setBoundaryVertical:(CGContextRef ) currentContext{
    if (self.graph.chart.xAxis){
        [self.graph.chart.xAxis setUpLine:currentContext];
        CGContextMoveToPoint(currentContext, 0, 0);
        CGContextAddLineToPoint(currentContext, 0, self.frame.size.height);
        CGContextStrokePath(currentContext);
    }
}

- (void)setBoundaryHorizontal:(CGContextRef ) currentContext{
    if (self.graph.chart.yAxis){
        [self.graph.chart.yAxis setUpLine:currentContext];
        CGContextMoveToPoint(currentContext,0, self.frame.size.height);
        CGContextAddLineToPoint(currentContext,self.frame.size.width, self.frame.size.height);
        CGContextStrokePath(currentContext);
    }
}

//@pragma draw series
- (NSArray *)getFirstLast{
    return @[@(0), @(self.graph.chart.chartData.count)];
}

- (void)drawGraphLine:(NSArray *)firstLast{
    for (UIView *view in self.subviews){
        [view removeFromSuperview];
    }
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    
    long lastMoveInd = [firstLast[0] integerValue] - 1;
    long firstInd = [firstLast[0] integerValue];
    for (long ind = firstInd; ind < [firstLast[1] integerValue]; ind++){
        NSArray *points = _graph.chart.chartData[ind];
        for (int i = 0; i< ((NSArray *)points[1]).count; i++){
            id val = points[1][i];
            UIBezierPath *path;
            if (paths.count < (i + 1) ){
                path = [UIBezierPath bezierPath];
                [path setLineWidth: [self lineWidth:i]];
                [paths addObject:path];
            } else {
                path = paths[i];
            };
            CGPoint pointP = [_graph pointByValueInGrid:@[points[0], val]];
            if ([val isKindOfClass:[NSNull class]] ){
                if (lastMoveInd != (ind -1) && [self fillSeries:i]){
                    [path addLineToPoint:CGPointMake( path.currentPoint.x, self.frame.size.height)];
                    [path moveToPoint: pointP];
                }
                lastMoveInd = ind;
            } else {
                if (self.graph.chart.nciShowPoints)
                    [self createPoint:pointP num:i];
                if (lastMoveInd == (ind -1)){
                    if ([self fillSeries:i]){
                        [path moveToPoint: CGPointMake(pointP.x, self.frame.size.height)];
                    } else {
                        [path moveToPoint:pointP];
                    }
                }
                [path addLineToPoint:pointP];
            }
        }
    }
    
    for (int i= 0; i < paths.count; i++){
        UIBezierPath *path = paths[i];
        UIColor *color = [self getColor:i];
        if ([self fillSeries:i] && !path.empty){
            [[color colorWithAlphaComponent:0.1] setFill];
            if (path.currentPoint.x == path.currentPoint.x)
                [path addLineToPoint:CGPointMake( path.currentPoint.x, self.frame.size.height)];
            [path fill];
            [path closePath];
        }
        [color setStroke];
        [path stroke];
    }
}

- (bool)fillSeries:(int)seriesNum{
    if (self.graph.chart.nciIsFill.count <= seriesNum){
        [self.graph.chart.nciIsFill addObject:@YES];
    }
    return [self.graph.chart.nciIsFill[seriesNum] boolValue];
}

- (void)createPoint:(CGPoint )point num:(int)num{
    float dim = 4;
    UIView *pointView = [[UIView alloc] initWithFrame:CGRectMake(point.x - dim/2, point.y - dim/2, dim, dim)];
    pointView.backgroundColor = [self getColor:num];
    [self addSubview:pointView];
}

//@pragma series properties
- (float )lineWidth:(int) i{
    float returnWidth;
    if (self.graph.chart.nciLineWidths &&
        (self.graph.chart.nciLineWidths.count > i) &&
        (![self.graph.chart.nciLineWidths[i] isKindOfClass:[NSNull class]])){
        returnWidth = [self.graph.chart.nciLineWidths[i] floatValue];
    } else {
        returnWidth = [self.graph.chart.nciLineWidths[0] floatValue];
    }
    return returnWidth;
}

- (UIColor *)getColor:(int) i{
    if (self.graph.chart.nciLineColors.count > i && ![self.graph.chart.nciLineColors[i] isKindOfClass:[NSNull class]]){
       return self.graph.chart.nciLineColors[i];
    } else {
        UIColor *newColor = [UIColor colorWithRed:(arc4random() % 255)/255.0f
                                            green:(arc4random() % 255)/255.0f
                                             blue:(arc4random() % 255)/255.0f alpha:1.0];
        if (self.graph.chart.nciLineColors.count > i){
             [self.graph.chart.nciLineColors replaceObjectAtIndex:i withObject:newColor];
        } else {
            [self.graph.chart.nciLineColors addObject:newColor];
        }
        return newColor;
    }
}

@end
