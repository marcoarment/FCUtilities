//
//  FCiOS11TableViewAnimationBugfix.h
//  Overcast
//
//  Created by Marco Arment on 10/30/17.
//  Copyright © 2017 Marco Arment. All rights reserved.
//

#ifndef FCiOS11TableViewAnimationBugfix_h
#define FCiOS11TableViewAnimationBugfix_h

inline __attribute__((always_inline)) void fc_iOS11TableViewAnimationBugfix(UIView *view)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [view.layer fc_removeAnimationsRecursive];
    });
}


#endif /* FCiOS11TableViewAnimationBugfix_h */
