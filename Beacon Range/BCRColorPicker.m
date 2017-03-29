//
//  BCRColorPicker.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-06-03.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import "BCRColorPicker.h"

@implementation BCRColorPicker

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width / 2, self.bounds.size.height / 2, 20, 20)];
    [self.color setFill];
    [[UIColor whiteColor] setStroke];
    path.lineWidth = 5;
    [path stroke];
    [path fill];
}

@end
