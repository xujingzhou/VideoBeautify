
#import "YoukuOAuthViewController.h"
#import "JZViewController.h"

@interface YoukuOAuthViewController () <UIWebViewDelegate>

@property (retain, nonatomic) UIWebView *webView;

- (void)startAuth;

@end

@implementation YoukuOAuthViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)initWebview
{
//    int navHeight = 44;
//    int statusHeight = 20;
//    BOOL hideNavBar = [self.navigationController isNavigationBarHidden];
//    BOOL hideStatus = [UIApplication sharedApplication].isStatusBarHidden;
    CGRect frame = self.view.frame;
//    if (!hideNavBar)
//    {
//        frame = CGRectMake(frame.origin.x, frame.origin.y+navHeight, frame.size.width, frame.size.height-navHeight);
//    }
//    if (!hideStatus)
//    {
//         frame = CGRectMake(frame.origin.x, frame.origin.y + statusHeight, frame.size.width, frame.size.height-statusHeight);
//    }
    
    _webView = [[UIWebView alloc]initWithFrame:frame];
    _webView.scalesPageToFit = NO;
    _webView.delegate = self;
    [self.view addSubview:_webView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initWebview];
    
	// Do any additional setup after loading the view.
    [self startAuth];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadWebPageWithString:(NSString*)urlString
{
    NSURL *url =[NSURL URLWithString:urlString];
    NSLog(@"url = %@", urlString);
    
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)startAuth
{
    NSString *path = [NSString stringWithFormat:@"https://openapi.youku.com/v2/oauth2/authorize?%@=%@&%@=%@&%@=%@", @"client_id", kYoukuAppKey, @"response_type", @"code", @"redirect_uri", kYoukuRedirectUri];
    [self loadWebPageWithString:path];
}

- (void)test
{
    NSURL *url = [NSURL URLWithString:@"https://openapi.youku.com"];
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:url];
    NSString *path = @"/v2/oauth2/authorize";
    NSDictionary *dic = @{@"client_id": kYoukuAppKey,
                          @"response_type": @"code",
                          @"redirect_uri": kYoukuRedirectUri};
    
    [client getPath:path parameters:dic success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        [self.webView loadData:responseObject MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"error : %@", error);
    }];
}

#pragma mark - web view delegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"did start with url ===> %@", webView.request.URL);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSRange range = NSMakeRange(0, kYoukuRedirectUri.length);
    __weak NSString *urlString = request.URL.absoluteString;
    if (urlString.length > range.length)
    {
        if ([[urlString substringWithRange:range] isEqualToString:kYoukuRedirectUri])
        {
            [webView stopLoading];
            
            NSRegularExpression *regx = [NSRegularExpression regularExpressionWithPattern:@"code=[0-9A-Za-z]+" options:NSRegularExpressionCaseInsensitive error:nil];
            NSTextCheckingResult *result = [regx firstMatchInString:urlString options:0 range:NSMakeRange(0, urlString.length)];
            NSRange foundRange = result.range;
            NSString *foundString = [urlString substringWithRange:foundRange];
            NSString *code = [foundString substringFromIndex:5];
            NSLog(@"url = %@", urlString);
            
            NSURL *url = [NSURL URLWithString:kApiYoukuBasePath];
            AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:url];
            NSDictionary *properties = @{@"client_id": kYoukuAppKey,
                                         @"client_secret": kYoukuAppScrect,
                                         @"grant_type": @"authorization_code",
                                         @"code": code,
                                         @"redirect_uri": kYoukuRedirectUri};
            [client postPath:kApiYoukuTokenPath parameters:properties success:^(AFHTTPRequestOperation *operation, id responseObject)
            {
                id json = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
                
                [[NSUserDefaults standardUserDefaults] setObject:json forKey:kOAuthCredential];
                [[NSUserDefaults standardUserDefaults] synchronize];

                 [self.navigationController popViewControllerAnimated:YES];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error)
            {
                NSLog(@"error : %@", error.userInfo);
                
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"did end with url ===> %@", webView.request);
//    NSString *test = [webView.request.URL absoluteString];
//    if ([test isEqualToString:kYoukuCallbackUrl])
//    {
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
}

@end
