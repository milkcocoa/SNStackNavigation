//
//  SNStackedViewController.m
//  StackedNavigationSample
//
//  Created by Shu MASUDA on 2011/12/04.
//

#import "SNStackedViewController.h"

#import "SNStackNavigationController.h"


static CGFloat  _SNStackedViewControllerViewWidth   = 476;


#pragma mark - SNStackedViewConroller () Interface


@interface SNStackedViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate
>

#pragma mark - Private Properties

@property (nonatomic, readwrite)    UITableView *itemsTableView;

#pragma mark - Private Methods

- (void)_initializeContentView;
- (void)_initializeTableView;

@end


#pragma makr - SNStackedViewController Implementation


@implementation SNStackedViewController


#pragma mark - Properties


@synthesize itemsTableView;


#pragma mark -


- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
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
    [self _initializeTableView];
}


- (void)_initializeContentView
{
    CGRect  frame;
    UIView  *contentView;

    frame = CGRectMake(0, 0, _SNStackedViewControllerViewWidth, CGRectGetHeight([[UIScreen mainScreen] bounds]));
    contentView = [[UIView alloc] initWithFrame:frame];
    [self setView:contentView];

    [contentView setAutoresizesSubviews:YES];
    [contentView setBackgroundColor:[UIColor lightGrayColor]];
}


- (void)_initializeTableView
{
    itemsTableView = [[UITableView alloc] initWithFrame:[[self view] bounds]
                                                  style:UITableViewStylePlain];
    [[self view] addSubview:itemsTableView];

    [itemsTableView setAutoresizesSubviews:YES];
    [itemsTableView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [itemsTableView setDataSource:self];
    [itemsTableView setDelegate:self];
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


#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const reuseIdentifier = @"cell";

    UITableViewCell *cell;
    NSInteger       row;

    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:reuseIdentifier];
    }

    row = [indexPath row];

    [[cell textLabel] setText:[NSString stringWithFormat:@"Item %d", row + 1]];

    return cell;
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SNStackNavigationController *navigationController;
    SNStackedViewController     *viewController;

    // UIViewController+StackNavigation.h is imported at .pch file.
    navigationController = [self stackNavigationController];

    viewController = [[SNStackedViewController alloc] initWithNibName:nil bundle:nil];

    [navigationController pushViewController:viewController
                          fromViewController:self
                                    animated:YES];
}


@end
