//
//  GMiPadAssignmentsViewController.h
//  GauchoMobile
//
//  Created by Aaron Dodson on 3/16/12.
//  Copyright (c) 2012 Me. All rights reserved.
//

#import "AssignmentsViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface GMiPadAssignmentsViewController : AssignmentsViewController {
    IBOutlet UILabel *date;
    IBOutlet UILabel *longDate;
}

@property (nonatomic, retain) UILabel *date;
@property (nonatomic, retain) UILabel *longDate;

@end
