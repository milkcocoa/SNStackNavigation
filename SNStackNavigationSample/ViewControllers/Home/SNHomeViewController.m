//
//  SNHomeViewController.m
//  StackedNavigationSample
//
//  Created by Shu MASUDA on 2011/12/04.
//

#import "SNHomeViewController.h"

#import "SNStackNavigationController.h"
#import "SNStackedViewController.h"


enum
{
    _tab1,
    _tab2,
    _tabMax,
};


static NSString * const _tabTitles[_tabMax] =
{
    @"Item 1",
    @"Item 2",
};


static CGFloat  _SNHomeViewControllerTabWidth   = 292;


#pragma mark - SNHomeViewController () Interface


@interface SNHomeViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate
>

#pragma mark - Private Methods

@property (strong, nonatomic)   UITableView                 *_tabTableView;
@property (strong, nonatomic)   SNStackNavigationController *_navigationController;

#pragma mark - Tab Items

@property (strong, nonatomic)   SNStackedViewController     *_stackedViewController1;

#pragma mark - Private Methods

- (void)_initializeContentView;
- (void)_initializeStackNavigationController;
- (void)_initializeTabTableView;

@end


#pragma mark - SNHomeViewController Implementation


@implementation SNHomeViewController


#pragma mark - Properties


@synthesize _navigationController;
@synthesize _stackedViewController1;
@synthesize _tabTableView;


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


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [self _initializeContentView];
    [self _initializeTabTableView];
    [self _initializeStackNavigationController];

    [self showTab1ViewController];
}


- (void)_initializeContentView
{
    [self setView:[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];

    [[self view] setAutoresizesSubviews:YES];
    [[self view] setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
}


- (void)_initializeTabTableView
{
    CGRect frame;

    frame = CGRectMake(0, 0, _SNHomeViewControllerTabWidth, CGRectGetHeight([[self view] bounds]));

    [self set_tabTableView:[[UITableView alloc] initWithFrame:frame]];
    [[self view] addSubview:_tabTableView];

    [_tabTableView setDataSource:self];
    [_tabTableView setDelegate:self];

    [_tabTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                               animated:NO
                         scrollPosition:UITableViewScrollPositionNone];
}


- (void)_initializeStackNavigationController
{
    [self set_navigationController:[[SNStackNavigationController alloc] initWithNibName:nil bundle:nil]];
    [[self view] addSubview:[_navigationController view]];

    [[_navigationController view] setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [[_navigationController view] setFrame:[[self view] bounds]];
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


- (void)showTab1ViewController
{
    if (!_stackedViewController1)
    {
        [self set_stackedViewController1:[[SNStackedViewController alloc] initWithNibName:nil bundle:nil]];
        [_stackedViewController1 setText:@"RootView Menu 1"];
    }

    [_navigationController pushViewController:_stackedViewController1
                           fromViewController:nil
                                     animated:YES];
}


- (void)showTab2ViewController
{

}


#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _tabMax;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const reuseIdentifier = @"cell";

    NSUInteger  row;

    UITableViewCell *cell;

    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:reuseIdentifier];
    }

    row = [indexPath row];

    [[cell textLabel] setText:_tabTitles[row]];

    return cell;
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}


@end
