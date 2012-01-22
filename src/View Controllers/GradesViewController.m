//
//  GradesViewController.m
//  Handles presentation and interaction with the list of grades
//  Created by Group J5 for CS48
//

#import "GradesViewController.h"

@implementation GradesViewController

@synthesize tableView;

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:24/255.0 green:69/255.0 blue:135/255.0 alpha:1.0];
    self.navigationController.visibleViewController.navigationItem.title = @"Grades";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    GMCourse *currentCourse = [[GMDataSource sharedDataSource] currentCourse];
    fetcher = [[GMSourceFetcher alloc] init];
    loadingView = [[GMLoadingView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 280) / 2, -25, 280, 27)];
    
    if ([[currentCourse grades] count] == 0) {
        [self loadGradesWithLoadingView:YES];
    }
    
    pendingID = 0;
    
    EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
    view.delegate = self;
    [self.tableView addSubview:view];
    reloadView = view;
    [view release];
	[reloadView refreshLastUpdatedDate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.visibleViewController.navigationItem.title = @"Grades";
    self.navigationController.visibleViewController.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [fetcher release];
    [loadingView removeFromSuperview];
    [reloadView removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - Data loading methods

- (void)loadGradesWithLoadingView:(BOOL)flag {
    if (!loading) {
        loading = YES;
        
        if (flag) {
            if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
                loadingView.frame = CGRectMake((int)(([[UIScreen mainScreen] bounds].size.height - 280) / 2), -25, 280, 27);
            else
                loadingView.frame = CGRectMake((int)(([[UIScreen mainScreen] bounds].size.width - 280) / 2), -25, 280, 27);
            
            loadingView.layer.zPosition = self.tableView.layer.zPosition + 1;
            [self.parentViewController.view addSubview:loadingView];
            [loadingView release];
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
            animation.fromValue = [NSValue valueWithCGPoint:loadingView.layer.position];
            animation.toValue = [NSValue valueWithCGPoint:CGPointMake(loadingView.layer.position.x, loadingView.layer.position.y + 25)];
            animation.duration = 0.25;
            animation.removedOnCompletion = NO;
            animation.fillMode = kCAFillModeForwards;
            [[loadingView layer] addAnimation:animation forKey:@"position"];
        }
        
        GMCourse *currentCourse = [[GMDataSource sharedDataSource] currentCourse];
        [fetcher gradesForCourse:currentCourse withDelegate:self];
    }
}

- (void)sourceFetchDidFailWithError:(NSError *)error {
    NSLog(@"Loading grades failed with error: %@", [error description]);

    loading = NO;
    [reloadView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.fromValue = [NSValue valueWithCGPoint:loadingView.layer.position];
    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(loadingView.layer.position.x, -25)];
    animation.duration = 0.25;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [[loadingView layer] addAnimation:animation forKey:@"position"];
}

- (void)sourceFetchSucceededWithPageSource:(NSString *)source {
    
    loading = NO;
    [reloadView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.fromValue = [NSValue valueWithCGPoint:loadingView.layer.position];
    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(loadingView.layer.position.x, -25)];
    animation.duration = 0.25;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [[loadingView layer] addAnimation:animation forKey:@"position"];
    
    [[[GMDataSource sharedDataSource] currentCourse] removeAllGrades];

    GMGradesParser *parser = [[GMGradesParser alloc] init];
    NSArray *grades = [parser gradesFromSource:source];
    
    for (GMGrade *grade in grades) {
        [[[GMDataSource sharedDataSource] currentCourse] addGrade:grade];
    }
    
    [parser release];
    
    [self.tableView reloadData];
    
    if ([grades count] == 0) {
        UITextField *label = [[UITextField alloc] initWithFrame:CGRectMake(0, (self.tableView.frame.size.height - 30) / 2 - 25, self.tableView.frame.size.width, 30)];
        label.enabled = NO;
        label.text = @"No Grades";
        label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:20.0];
        label.textColor = [UIColor grayColor];
        label.textAlignment = UITextAlignmentCenter;
        [self.tableView addSubview:label];
        [label release];
    }
    
    if (pendingID != 0) {
        [self showGradeWithID:[NSNumber numberWithInteger:pendingID]];
        pendingID = 0;
    }
}

#pragma mark - Animation methods

- (void)showGradeWithID:(NSNumber *)gradeID {
    if ([[[[GMDataSource sharedDataSource] currentCourse] grades] count] != 0) {
        
        NSArray *grades = [[[GMDataSource sharedDataSource] currentCourse] grades];
        
        for (int i = 0; i < [grades count]; i++) {
            if (((GMGrade *)[grades objectAtIndex:i]).gradeID == [gradeID integerValue]) {
                GMGrade *grade = [grades objectAtIndex:i];
                
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                
                CAGradientLayer *layer = [[CAGradientLayer alloc] init];
                
                CGColorRef first = [[UIColor colorWithRed:242/255.0 green:206/255.0 blue:68/255.0 alpha:1.0] CGColor];
                CGColorRef second = [[UIColor colorWithRed:239/255.0 green:172/255.0 blue:30/255.0 alpha:1.0] CGColor];
                
                layer.colors = [NSArray arrayWithObjects:(id)first, (id)second, nil];
                layer.cornerRadius = 15.0;
                layer.borderWidth = 1.0;
                layer.borderColor = [[UIColor grayColor] CGColor];
                layer.frame = CGRectMake(0, i * 50, [self.tableView frame].size.width, 50);
                [self.tableView.layer addSublayer:layer];
                [layer release];
                
                CATextLayer *percentage = [[CATextLayer alloc] init];
                percentage.frame = CGRectMake(10, 11, layer.frame.size.width - 20, layer.frame.size.height - 10);
                CGFontRef percentageFont = CGFontCreateWithFontName((CFStringRef)[UIFont fontWithName:@"Helvetica-Bold" size:30.0].fontName);
                percentage.font = percentageFont;
                CGFontRelease(percentageFont);
                percentage.fontSize = 30.0;
                percentage.foregroundColor = [[UIColor blackColor] CGColor];
                percentage.contentsScale = [[UIScreen mainScreen] scale];
                if (grade.score != -1)
                    percentage.string = [NSString stringWithFormat:@"%i%%", (int)((double)grade.score / (double)grade.max * 100.0)];
                else
                    percentage.string = @"–";
                [layer addSublayer:percentage];
                [percentage release];
                
                CATextLayer *description = [[CATextLayer alloc] init];
                description.frame = CGRectMake(100, 8, layer.frame.size.width - 80, 30);
                CGFontRef descriptionFont = CGFontCreateWithFontName((CFStringRef)[UIFont fontWithName:@"Helvetica-Bold" size:18.0].fontName);
                description.font = descriptionFont;
                CGFontRelease(descriptionFont);
                description.fontSize = 18.0;
                description.foregroundColor = [[UIColor blackColor] CGColor];
                description.contentsScale = [[UIScreen mainScreen] scale];
                description.string = grade.description;
                [layer addSublayer:description];
                [description release];
                
                CATextLayer *outof = [[CATextLayer alloc] init];
                outof.frame = CGRectMake(100, 30, layer.frame.size.width - 80, 14);
                CGFontRef outofFont = CGFontCreateWithFontName((CFStringRef)[UIFont fontWithName:@"Helvetica" size:12.0].fontName);
                outof.font = outofFont;
                CGFontRelease(outofFont);
                outof.fontSize = 12.0;
                outof.foregroundColor = [[UIColor grayColor] CGColor];
                outof.contentsScale = [[UIScreen mainScreen] scale];
                if (grade.score != -1)
                    outof.string = [NSString stringWithFormat:@"%i out of %i", grade.score, grade.max];
                else
                    outof.string = @"Not Graded";
                [layer addSublayer:outof];
                [outof release];
                
                //From http://stackoverflow.com/questions/2690775/creating-a-pop-animation-similar-to-the-presentation-of-uialertview
                CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                                  animationWithKeyPath:@"transform"];
                
                CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
                CATransform3D scale2 = CATransform3DMakeScale(1.2, 1.2, 1);
                CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
                CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
                
                NSArray *frameValues = [NSArray arrayWithObjects:
                                        [NSValue valueWithCATransform3D:scale1],
                                        [NSValue valueWithCATransform3D:scale2],
                                        [NSValue valueWithCATransform3D:scale3],
                                        [NSValue valueWithCATransform3D:scale4],
                                        nil];
                [animation setValues:frameValues];
                
                NSArray *frameTimes = [NSArray arrayWithObjects:
                                       [NSNumber numberWithFloat:0.0],
                                       [NSNumber numberWithFloat:0.5],
                                       [NSNumber numberWithFloat:0.9],
                                       [NSNumber numberWithFloat:1.0],
                                       nil];    
                [animation setKeyTimes:frameTimes];
                
                animation.fillMode = kCAFillModeForwards;
                animation.removedOnCompletion = NO;
                animation.duration = .4;
                animation.delegate = self;
                [animation setValue:layer forKey:@"layer"];
                
                [layer addAnimation:animation forKey:@"popup"];
                
                return;
            }
        }
    } else {
        pendingID = [gradeID integerValue];
    }
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    if ([theAnimation valueForKey:@"layer"] != nil) {
        [(CALayer *)[theAnimation valueForKey:@"layer"] removeFromSuperlayer];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int rows = [[[[GMDataSource sharedDataSource] currentCourse] grades] count];
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    GMGradesTableViewCell *cell = (GMGradesTableViewCell *)[table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[GMGradesTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    GMGrade *grades = [[[[GMDataSource sharedDataSource] currentCourse] grades] objectAtIndex:indexPath.row];
    cell.description.text = grades.description;
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (grades.score == -1){
        cell.percentage.text = @"–";
        cell.outof.text = @"Not Graded";   
    }
    else {
    cell.percentage.text = [NSString stringWithFormat:@"%i%%", (int)((double)grades.score / (double)grades.max * 100.0)];
    cell.outof.text = [NSString stringWithFormat:@"%i out of %i", grades.score, grades.max];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GMGrade *grade = [[[[GMDataSource sharedDataSource] currentCourse] grades] objectAtIndex:indexPath.row];
    
    UITabBarController *controller = (UITabBarController *)(self.navigationController.visibleViewController);
    controller.selectedViewController = [[controller viewControllers] objectAtIndex:1];
    [[[controller viewControllers] objectAtIndex:1] performSelector:@selector(showAssignmentWithID:) withObject:[NSNumber numberWithInteger:grade.gradeID]];
    
    [table deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Reload view methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {	
	
	[reloadView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	
	[reloadView egoRefreshScrollViewDidEndDragging:scrollView];
}

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view {
	
	[self loadGradesWithLoadingView:NO];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView *)view {
	
	return loading;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView *)view {
	
	return [NSDate date];
}

@end
