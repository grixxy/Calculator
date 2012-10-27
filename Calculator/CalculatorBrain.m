//
//  CalculatorBrain.m
//  Calculator
//
//  Created by Gregory on 8/24/12.
//  Copyright (c) 2012 Gregory. All rights reserved.
//

#import "CalculatorBrain.h"

@interface CalculatorBrain()


@property (nonatomic, strong) NSMutableArray *programStack;
@property (nonatomic, weak) NSDictionary *variables;
@end


@implementation CalculatorBrain

@synthesize programStack = _programStack;
@synthesize variables = _variables;

- (NSMutableArray *)programStack
{
    if (_programStack == nil) _programStack = [[NSMutableArray alloc] init];
    return _programStack;
}

- (id)program
{
    return [self.programStack copy];
}


- (void)pushOperand:(double)operand
{
    [self.programStack addObject:[NSNumber numberWithDouble:operand]];
}

- (void) clearModel {
    [self.programStack removeAllObjects];
}


+ (NSString *)descriptionOfProgram:(id)program
{
    NSMutableArray *stack = [program mutableCopy];
    NSString * description = [self descriptionOfTopOfStack:stack];
    return description;
}


- (double)performOperation:(NSString *)operation
{
    [self.programStack addObject:operation];
    return [[self class] runProgram:self.program];
}

+ (NSString*)descriptionOfTopOfStack:(NSMutableArray *)stack{
    NSString *result;
    id topOfStack = [stack lastObject];
    if (topOfStack) [stack removeLastObject];
    if ([topOfStack isKindOfClass:[NSNumber class]]){
    // is a number
        result = [topOfStack description];
    } else if([self isVariable:topOfStack inProgram:stack]||[self isNotOperand:topOfStack]){
        // is variable or not an operand
        result = topOfStack;
    }
    else if ([self isSingleOperandOperation:topOfStack]){
    //single operand
        result = topOfStack;
        result = [result stringByAppendingString: @"("];
        result = [result stringByAppendingString:[self descriptionOfTopOfStack:stack]];
        result = [result stringByAppendingString:@")"];

    }
    else if ([self isFirstPriorityMultiOperandOperation:topOfStack]){
    //multiOperand * /
        NSString *firstOperand;
        NSString *secondOperand;
        NSString *prefix = @"";
        NSString *postfix = @"";
        if([self nextOperationInStackIsSecondPriority:stack]){
            prefix = @"(";
            postfix = @")";
        }
        secondOperand = [prefix stringByAppendingString:[self descriptionOfTopOfStack:stack]];
        secondOperand = [secondOperand stringByAppendingString:postfix];
        
        
        if([self nextOperationInStackIsSecondPriority:stack]){
          prefix = @"(";
          postfix = @")";
        } else {
            prefix = @"";
            postfix = @"";
        }
        
        firstOperand = [prefix stringByAppendingString:[self descriptionOfTopOfStack:stack]];
        firstOperand = [firstOperand stringByAppendingString:postfix];
        
        result = [firstOperand stringByAppendingString:topOfStack];
        result = [result stringByAppendingString:secondOperand];
        
    } else if ([self isSecondPriorityMultiOperandOperation:topOfStack]){
        //multiOperand - +
        NSString *firstOperand;
        NSString *secondOperand;
        secondOperand = [self descriptionOfTopOfStack:stack];
        firstOperand = [self descriptionOfTopOfStack:stack];
        result = [firstOperand stringByAppendingString:topOfStack];
        result = [result stringByAppendingString:secondOperand];
    
    }
    return result;

}

+ (BOOL) nextOperationInStackIsSecondPriority:(NSArray *)stack {
    BOOL result = FALSE;
    id topOfStack = [stack lastObject];
    if([self isSecondPriorityMultiOperandOperation:topOfStack]){
        result = TRUE;
    }
    return result;

}

+ (double)popOperandOffProgramStack:(NSMutableArray *)stack
{
    double result = 0;
    
    id topOfStack = [stack lastObject];
    if (topOfStack) [stack removeLastObject];
    
    if ([topOfStack isKindOfClass:[NSNumber class]])
    {
        result = [topOfStack doubleValue];
    } else if([[self variablesUsedInProgram:stack] containsObject: topOfStack] ){
        //not assigned variables
        result = 0;
    }
    else if ([topOfStack isKindOfClass:[NSString class]])
    {
        NSString *operation = topOfStack;
        if ([operation isEqualToString:@"+"]) {
            result = [self popOperandOffProgramStack:stack] +
            [self popOperandOffProgramStack:stack];
        } else if ([@"*" isEqualToString:operation]) {
            result = [self popOperandOffProgramStack:stack] *
            [self popOperandOffProgramStack:stack];
        } else if ([operation isEqualToString:@"-"]) {
            double subtrahend = [self popOperandOffProgramStack:stack];
            result = [self popOperandOffProgramStack:stack] - subtrahend;
        } else if ([operation isEqualToString:@"/"]) {
            double divisor = [self popOperandOffProgramStack:stack];
            if (divisor) result = [self popOperandOffProgramStack:stack] / divisor;
        } else if([@"sin" isEqualToString:operation]){
            result = sin([self popOperandOffProgramStack:stack]);
        } else if([@"cos" isEqualToString:operation]){
            result = cos([self popOperandOffProgramStack:stack]);
        } else if([@"sqrt" isEqualToString:operation]){
            result = sqrt([self popOperandOffProgramStack:stack]);
        } else if([@"π" isEqualToString:operation]){
            result = M_PI;
        }
    }
    
    return result;
}

+ (double)runProgram:(id)program
{
    NSMutableArray *stack;
    if ([program isKindOfClass:[NSArray class]]) {
        stack = [program mutableCopy];
    }
    return [self popOperandOffProgramStack:stack];
}

+ (double)runProgram:(id)program usingVariableValues:(NSDictionary *)variableValues{
    NSMutableArray *stack;
    NSSet *variables = [self variablesUsedInProgram:program];
    if ([program isKindOfClass:[NSArray class]]) {
        stack = [program mutableCopy];
        int i;
        for (i = 0; i < [stack count]; i++) {
            id programElement = [stack objectAtIndex:i];
            if([variables containsObject:programElement]){
                [stack replaceObjectAtIndex:i withObject:[variableValues valueForKey:programElement]];
            }
        }
    }

    return [self runProgram:stack];
}

+ (NSSet *)variablesUsedInProgram:(id)program{
    NSMutableSet * variables = nil;
    if ([program isKindOfClass:[NSArray class]]) {
        int i;
        for (i = 0; i < [program count]; i++) {
            id programElement = [program objectAtIndex:i];
            if([programElement isKindOfClass:[NSString class]] && [self isOperation:programElement]){
                if(variables==nil) variables = [[NSMutableSet alloc] init];
                [variables addObject:programElement];
                
            }
        }
        
    }
    return variables;
 
}

+ (BOOL)isOperation:(NSString *)operation{
    return [self isSingleOperandOperation:operation] || [self isMultiOperandOperation:operation];
}
+ (BOOL)isSingleOperandOperation:(NSString *)operation{
    NSSet * possibleOperations = [NSSet setWithObjects:@"sin",@"cos",@"sqrt", nil];
    BOOL isOperation = [possibleOperations containsObject:operation];
    NSLog(@"is SingleOperation %@\n", (isOperation ? @"YES" : @"NO"));
    return isOperation;
    
}

+ (BOOL)isMultiOperandOperation:(NSString *)operation{
   return [self isFirstPriorityMultiOperandOperation:operation] || [self isSecondPriorityMultiOperandOperation:operation];
    
}

+ (BOOL)isFirstPriorityMultiOperandOperation:(NSString *)operation{
    NSSet * possibleOperations = [NSSet setWithObjects:@"/", @"*", nil];
    BOOL isOperation = [possibleOperations containsObject:operation];
    NSLog(@"is isFirstPriorityMultiOperandOperation %@\n", (isOperation ? @"YES" : @"NO"));
    return isOperation;
    
}

+ (BOOL)isSecondPriorityMultiOperandOperation:(NSString *)operation{
    NSSet * possibleOperations = [NSSet setWithObjects:@"+",@"-", nil];
    BOOL isOperation = [possibleOperations containsObject:operation];
    NSLog(@"is isSecondPriorityMultiOperandOperation %@\n", (isOperation ? @"YES" : @"NO"));
    return isOperation;
   
}


+(BOOL) isNotOperand: (NSString*) stackObject {
    BOOL result = false;
    if([stackObject isEqualToString:@"π"]) result = TRUE;
    return result;
}

+(BOOL) isVariable:(NSString*) stackObject inProgram:(id) program{
    return [[self variablesUsedInProgram:program] containsObject:stackObject];
}





@end
