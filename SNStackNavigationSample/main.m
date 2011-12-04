//
//  main.m
//  StackedNavigationSample
//
//  Created by Shu MASUDA on 2011/12/04.
//

#import <UIKit/UIKit.h>

#import "SNAppDelegate.h"


int main(int argc, char *argv[])
{
    @autoreleasepool
    {
        @try
        {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([SNAppDelegate class]));
        }
        @catch (NSException *exception)
        {
            NSLog(@"%@", [exception callStackSymbols]);

            @throw exception;
        }
    }
}
