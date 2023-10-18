//
//  ExpressionSolver.m
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 18/10/23.
//

#import <Foundation/Foundation.h>
#import "ExpressionSolver.h"

@implementation ExpressionSolver

+(NSNumber *)solveExpression:(NSString *)string {
    id value;
    @try {
        NSExpression *ex = [NSExpression expressionWithFormat:string];
        value = [ex expressionValueWithObject:nil context:nil];
    } @catch (NSException *e) {
        value = nil;
    }
    return value;
}

@end

