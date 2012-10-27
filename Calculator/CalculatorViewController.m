//
//  CalculatorViewController.m
//  Calculator
//
//  Created by Gregory on 8/16/12.
//  Copyright (c) 2012 Gregory. All rights reserved.
//

#import "CalculatorViewController.h"
#import "CalculatorBrain.h"

@interface CalculatorViewController ()
@property (nonatomic) BOOL userIsInTheMiddleOfEditingANumber;
@property (nonatomic, strong) CalculatorBrain *brain;
@end

@implementation CalculatorViewController
@synthesize display;
@synthesize historyDisplay;
@synthesize userIsInTheMiddleOfEditingANumber;
@synthesize brain = _brain;

-(CalculatorBrain *)brain {
    if(!_brain) _brain = [[CalculatorBrain alloc] init];
    return _brain;
    
}

- (IBAction)digitPressed:(UIButton *)sender {
    NSString *digit = [ sender currentTitle];
    if(self.userIsInTheMiddleOfEditingANumber){
       self.display.text = [self.display.text stringByAppendingString:digit];
    } else {
        self.display.text = digit;
        self.userIsInTheMiddleOfEditingANumber = TRUE;
    }
    
}

- (void)updateDisplayHistory {
    self.historyDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
    
}
- (IBAction)enterPressed {
    [self.brain pushOperand: [self.display.text doubleValue]];
    [self updateDisplayHistory];
    self.userIsInTheMiddleOfEditingANumber = NO;
}



- (IBAction)operationPressed:(id)sender {
    if(self.userIsInTheMiddleOfEditingANumber){
        [self enterPressed];
    }
    NSString *operation = [sender currentTitle];
    double result = [self.brain performOperation:operation];
    [self updateDisplayHistory];
    self.display.text = [NSString stringWithFormat:@"%g", result];
}

- (IBAction)decimalPointPressed {
    NSString *pointString = @".";
    if([self.display.text rangeOfString:pointString].location == NSNotFound){
      self.display.text = [self.display.text stringByAppendingString:pointString];  
      self.userIsInTheMiddleOfEditingANumber = TRUE;
    }
}

- (IBAction)clearPressed {
    self.display.text = @"0";
    self.historyDisplay.text = @"";
    [self.brain clearModel];
    
}

- (IBAction)backspacePressed {
    NSString *currentText = self.display.text;
    if(self.userIsInTheMiddleOfEditingANumber && ![currentText isEqualToString:@"0"]){
        int currentLabelSize = [currentText length];
        if(currentLabelSize == 1){
           self.display.text = @"0";
            self.userIsInTheMiddleOfEditingANumber = FALSE;
        } else {
            self.display.text = [self.display.text substringToIndex:currentLabelSize-1];
        }
    }
}

- (void)viewDidUnload {
    [self setHistoryDisplay:nil];
    [super viewDidUnload];
}
@end
