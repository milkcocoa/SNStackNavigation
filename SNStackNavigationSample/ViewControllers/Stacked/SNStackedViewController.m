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

@property (strong, nonatomic)   UILabel *_label;

#pragma mark - Private Methods

- (void)_initializeContentView;
- (void)_initializeTableView;

@end


#pragma makr - SNStackedViewController Implementation


@implementation SNStackedViewController


#pragma mark - Properties


@synthesize _label;

@synthesize text;


- (void)setText:(NSString *)aText
{
    if (text != aText)
    {
        text = aText;
        [_label setText:text];
    }
}


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
    UITableView *tableView;

    tableView = [[UITableView alloc] initWithFrame:[[self view] bounds]
                                             style:UITableViewStylePlain];
    [[self view] addSubview:tableView];

    [tableView setAutoresizesSubviews:YES];
    [tableView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [tableView setDataSource:self];
    [tableView setDelegate:self];
}


- (void)_initializeLabel
{
    UILabel *label;

    label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100, 16)];
    [[self view] addSubview:label];

    [label setAutoresizingMask:(UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
                                UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin)];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setCenter:[[self view] center]];
    [label setText:text];
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
    [viewController setText:[NSString stringWithFormat:@"Stack %d", [[navigationController viewControllers] count] + 1]];

    [navigationController pushViewController:viewController
                          fromViewController:self
                                    animated:YES];
}


@end
