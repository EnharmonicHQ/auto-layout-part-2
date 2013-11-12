//
//  ENHViewController.m
//  AutolayoutPartDeux
//
//  Created by Jonathan Saggau on 4/11/13.
//  Copyright (c) 2013 Enharmonic. All rights reserved.
//

#import "ENHViewController.h"

@interface ENHViewController ()
@property (weak, nonatomic) IBOutlet UIView *redView;
@property (weak, nonatomic) IBOutlet UIView *purpleView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) NSLayoutConstraint *interestingConstraint;
@property (nonatomic)float currentConstant;
@end

@implementation ENHViewController
{
    dispatch_source_t _timer;
    BOOL _timerRunning;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (!_timer)
    {
        [self initTimer];
    }
    
	// Do any additional setup after loading the view, typically from a nib.
    [self.view removeConstraints:self.view.constraints];
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings (_redView, _purpleView);
    NSArray *constraintsStrings = @[@"H:|[_redView]|",
                                    @"H:|[_purpleView]|",
                                    [NSString stringWithFormat:@"V:|[_redView(>=80@1000)][_purpleView(==%@@%@)]|",
                                     @(floorf([self.slider value])), @(UILayoutPriorityDefaultHigh)],
                                    ];
    NSArray *lastConstraintArray = nil;
    for (NSString *constraintString in constraintsStrings)
    {
        lastConstraintArray = [NSLayoutConstraint constraintsWithVisualFormat: constraintString
                                                                      options: 0
                                                                      metrics: nil
                                                                        views: viewsDictionary];
        [self.view addConstraints:lastConstraintArray];

    }

    for (NSLayoutConstraint *constraint in lastConstraintArray)
    {
        if ([constraint.firstItem isEqual:self.purpleView] &&
            constraint.firstAttribute == NSLayoutAttributeHeight)
        {
            NSLog(@"CONSTRAINT: item1:%@ attr1:%d relation:%d item2:%@ attr2:%d multiplier:%f",
                  constraint.firstItem,
                  constraint.firstAttribute,
                  constraint.relation,
                  constraint.secondItem,
                  constraint.secondAttribute,
                  constraint.multiplier);
            [self setInterestingConstraint:constraint];
            break;
        }
    }
}

-(void)updateViewConstraints
{
    [super updateViewConstraints];
    [self startTimer];
}

- (IBAction)sliderChanged:(id)sender
{
    NSLog(@"%@ %@ %@", self, NSStringFromSelector(_cmd), @([(UISlider *)sender value]));
    [self.view setNeedsUpdateConstraints];
}

-(void)initTimer
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue); //run event handler on the default global queue
    dispatch_time_t now = dispatch_walltime(DISPATCH_TIME_NOW, 0);
    dispatch_source_set_timer(_timer, now, 1.0f/30.0f * NSEC_PER_SEC, 1.0f/300.0f);

    __weak typeof(self) blkSelf = self;
    dispatch_source_set_event_handler(_timer, ^{

        NSLayoutConstraint *constraintToMod = [self interestingConstraint];
        float targetConstant = floorf([blkSelf.slider value]);

        float adder = (targetConstant - blkSelf.currentConstant) * .234;
        blkSelf.currentConstant += adder;
        if (fabsf(targetConstant - blkSelf.currentConstant) <= 1.0f)
        {
            blkSelf.currentConstant = targetConstant;
        }

        //        NSLog(@"tick-tock CUR:%f TAR:%f ADD:%f", blkSelf.currentConstant, targetConstant, adder);

        dispatch_async(dispatch_get_main_queue(), ^{
            [constraintToMod setConstant:floorf(blkSelf.currentConstant)];
        });

        if (targetConstant == blkSelf.currentConstant)
        {
            NSLog(@"STOP!");
            [blkSelf stopTimer];
        }
    });
}

-(void)startTimer
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    @synchronized(self)
    {
        if (!_timerRunning)
        {
            _timerRunning = YES;
            dispatch_resume(_timer);
        }
    }
}

-(void)stopTimer
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    @synchronized(self)
    {
        if (_timerRunning)
        {
            _timerRunning = NO;
            dispatch_suspend(_timer);
        }
    }
}


@end
