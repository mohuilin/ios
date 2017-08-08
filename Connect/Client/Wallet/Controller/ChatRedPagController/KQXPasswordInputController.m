//
//  KQXPasswordInputController.m
//  KQXPasswordInput
//
//  Created by Qingxu Kuang on 16/8/23.
//  Copyright © 2016年 Asahi Kuang. All rights reserved.
//

@interface KQXPasswordInputController (){
    CAShapeLayer *shapeLayer;
}
@property(weak, nonatomic) IBOutlet UIButton *closeButton;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property(weak, nonatomic) IBOutlet UITextField *inputTextField;
@property(weak, nonatomic) IBOutlet UIView *symbolView;
@property(weak, nonatomic) IBOutlet UIView *bodyView;

@property(assign, nonatomic) KQXPasswordCategory category;

@property(strong, nonatomic) NSMutableArray *spotArray;
@property(strong, nonatomic) NSMutableArray *circleArray;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *bodyCenterToX;

@property (nonatomic ,copy) NSString *fristPassword;
@property (nonatomic, copy) CompleteWithSelfBlock completeWithSelfBlock;

@property(weak, nonatomic) IBOutlet NSLayoutConstraint *bodyViewHeightConstraint;
@end

@implementation KQXPasswordInputController

#define RGB(r, g, b) [UIColor colorWithRed:r/255.f green:g/255.f blue:b/255.f alpha:1.f]

#define k_BODY_VIEW_WIDTH 270.f
#define K_NUMBER_PASSWORD (int)4
#define K_SPOT_RADIUS 12.5

#pragma mark - lazy loading

- (NSMutableArray *)spotArray {
    if (!_spotArray) {
        _spotArray = @[].mutableCopy;
    }
    return _spotArray;
}

- (NSMutableArray *)circleArray {
    if (!_circleArray) {
        _circleArray = @[].mutableCopy;
    }
    return _circleArray;
}

- (instancetype)initWithPasswordCategory:(KQXPasswordCategory)category complete:(CompleteWithSelfBlock)complete{
    if (self = [super init]) {
        [self setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        [self setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        self.category = category;
        self.completeWithSelfBlock = complete;
    }
    return self;
}

#pragma mark --

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self drawCircle];
    [self drawSpot];
    [self observerAdded];

    self.descriptionLabel.numberOfLines = 0;
    
    switch (self.category) {
        case KQXPasswordCategorySet:
        {
            self.titleLabel.text = LMLocalizedString(@"Wallet Set the password", nil);
            self.descriptionLabel.text = LMLocalizedString(@"Wallet Enter 4 Digits", nil);
        }
            break;
            
        case KQXPasswordCategoryVerify:
        {
            self.titleLabel.text = LMLocalizedString(@"Wallet Verify password", nil);
            self.descriptionLabel.text = LMLocalizedString(@"Wallet Enter 4 Digits", nil);
        }
            break;
            
        default:
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {

    [self clearContents];
    [super viewWillDisappear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {

    [_inputTextField becomeFirstResponder];
    [super viewDidAppear:animated];
    
}

- (void)viewDidLayoutSubviews {

    CGFloat symbol_total = (k_BODY_VIEW_WIDTH - 100);
    CGFloat spot_halfWidth = K_SPOT_RADIUS / 2;
    CGFloat spot_x = symbol_total / K_NUMBER_PASSWORD;
    CGFloat symbolView_h = CGRectGetHeight(_symbolView.frame);

    // circle layout
    for (int i = 0; i < [self.spotArray count]; i++) {
        CAShapeLayer *spot = [self.spotArray objectAtIndexCheck:i];
        CAShapeLayer *circle = [self.circleArray objectAtIndexCheck:i];
        [spot setPosition:CGPointMake((spot_x / 2 - spot_halfWidth) + i * spot_x, symbolView_h / 2 - spot_halfWidth)];
        [circle setPosition:CGPointMake((spot_x / 2 - spot_halfWidth) + i * spot_x, symbolView_h / 2 - spot_halfWidth)];
    }

    [super viewDidLayoutSubviews];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:_inputTextField];
}

#pragma mark - Methods

- (void)clearContents {
    [_inputTextField setText:nil];
    for (CAShapeLayer *spot in self.spotArray) {
        [spot setHidden:YES];
    }
}

- (void)observerAdded {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputContentsChanged:) name:UITextFieldTextDidChangeNotification object:_inputTextField];
}

- (void)drawSpot {
    for (int i = 0; i < K_NUMBER_PASSWORD; i++) {
        UIBezierPath *spotBezier = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.f, 0.f, K_SPOT_RADIUS, K_SPOT_RADIUS)];
        CAShapeLayer *spot = [CAShapeLayer layer];
        [spot setPath:spotBezier.CGPath];
        [spot setFillColor:RGB(56, 66, 95).CGColor];
        [spot setHidden:YES];
        [self.spotArray objectAddObject:spot];
        [_symbolView.layer insertSublayer:spot atIndex:0];
    }
}

- (void)drawCircle {
    for (int i = 0; i < K_NUMBER_PASSWORD; i++) {
        UIBezierPath *spotBezier = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.f, 0.f, K_SPOT_RADIUS, K_SPOT_RADIUS)];
        CAShapeLayer *spot = [CAShapeLayer layer];
        [spot setPath:spotBezier.CGPath];
        [spot setStrokeColor:RGB(56, 66, 95).CGColor];
        [spot setFillColor:[UIColor clearColor].CGColor];
        [spot setLineWidth:1.f];
        [self.circleArray objectAddObject:spot];
        [_symbolView.layer insertSublayer:spot atIndex:0];
    }
}

#pragma mark - selectors

- (void)inputContentsChanged:(NSNotification *)notification {
    UITextField *textField = notification.object;
    NSInteger length = [textField.text length];
    if (length > K_NUMBER_PASSWORD) {
        // Enter more than 4 truncated text
        textField.text = [textField.text substringToIndex:K_NUMBER_PASSWORD];
        return;
    };
    [self.spotArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CAShapeLayer *spot = (CAShapeLayer *) obj;
        spot.hidden = idx < length ? NO : YES;
    }];
    if (length == K_NUMBER_PASSWORD) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self clearContents];
        });
        switch (self.category) {
            case KQXPasswordCategorySet:
            {
                if (self.fristPassword) {
                    if ([self.fristPassword isEqualToString:textField.text]) {
                        [self dismiss:nil];
                        if (self.completeWithSelfBlock) {
                            self.completeWithSelfBlock(self,self.fristPassword);
                        }
                    } else { /// tip pass not match
                        self.titleLabel.text = LMLocalizedString(@"Wallet Set the password", nil);
                        self.descriptionLabel.text = LMLocalizedString(@"Wallet The two passwords are not consistent please input again", nil);
                        [self shakeTipLabel];
                    }
                } else {
                    self.titleLabel.text = LMLocalizedString(@"Wallet Set the password", nil);
                    self.descriptionLabel.text = LMLocalizedString(@"Wallet Please enter the four digit Numbers again", nil);
                    self.fristPassword = textField.text;
                }
            }
                break;
                
            case KQXPasswordCategoryVerify:
            {
                if (self.completeWithSelfBlock) {
                    self.completeWithSelfBlock(self,textField.text);
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)shakeTipLabel{
    CAKeyframeAnimation *shakeAnim = [CAKeyframeAnimation animation];
    shakeAnim.keyPath = @"transform.translation.x";
    shakeAnim.duration = 0.15;
    CGFloat delta = 10;
    shakeAnim.values = @[@0 , @(-delta), @(delta), @0];
    shakeAnim.repeatCount = 2;
    [self.descriptionLabel.layer addAnimation:shakeAnim forKey:nil];
}

- (void)verfilySuccess:(BOOL)success{
    if (success) {
        [self dismiss:nil];
    } else {
        self.descriptionLabel.text = LMLocalizedString(@"Login Password incorrect", nil);
        [self shakeTipLabel];
    }
}

- (IBAction)dismiss:(id)sender {
    [_inputTextField resignFirstResponder];
    [self dismissViewControllerAnimated:NO completion:^{
        if ([self.delegate respondsToSelector:@selector(passwordInputControllerDidClosed)]) {
            [self.delegate passwordInputControllerDidClosed];
        }
    }];
}

@end
