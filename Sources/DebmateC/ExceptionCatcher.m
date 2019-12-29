//
//  ExceptionCatcher.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

#import <Foundation/Foundation.h>

bool Debmate_CatchException(void (^b)(void)) {
    @try {
        b();
        return true;
    }
    @catch (NSException *e) {
        return false;
    }
}
