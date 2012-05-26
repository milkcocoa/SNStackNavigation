//
//  SNRootViewController.m
//  StackedNavigationSample
//
//  Created by Shu MASUDA on 2011/12/04.
//

#import "SNRootViewController.h"

#import "SNHomeViewController.h"


#pragma mark - SNRootViewController () Interface


@interface SNRootViewController ()

#pragma mark - Private Properties

@property (strong, nonatomic)   SNHomeViewController    *_homeViewController;

#pragma mark - Private Methodsn

- (void)_initializeContentView;
- (void)_initializeHomeViewController;

@end


#pragma mark - SNRootViewController Implementation


@implementation SNRootViewController


#pragma mark - Properties


@synthesize _homeViewController;


#pragma mark -


- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self)
    {

    }

    return self;
}


- (void)loadView
{
    [self _initializeContentView];
    [self _initializeHomeViewController];
}


- (void)_initializeContentView
{
    [self setView:[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];

    [[self view] setAutoresizesSubviews:YES];
    [[self view] setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
}


- (void)_initializeHomeViewController
{
    [self set_homeViewController:[[SNHomeViewController alloc] initWithNibName:nil bundle:nil]];
    [[self view] addSubview:[_homeViewController view]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [_homeViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                                          duration:duration];
}


@end
