//
//  ExpressionSolver.h
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 18/10/23.
//

#import <Foundation/Foundation.h>

@interface ExpressionSolver : NSObject
+(NSNumber *)solveExpression:(NSString *)string;
@end

