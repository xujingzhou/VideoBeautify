
#import "ThemeScrollView.h"

#define THEME_H_PADDING   20.0f
#define THEME_H_START     10.0f
#define THEME_TAG_BASE    100

@interface ThemeScrollView ()

@property(nonatomic, assign) CGFloat          startXPosition;     /*< 开始位置 >*/
@property(nonatomic, assign) CGFloat          themeHPadding;      /*< 每个主题之间的间隔 >*/
@property(nonatomic, strong) UIImageView     *bgImageView;        /*< 背景图视图 >*/
@property(nonatomic, strong) UIScrollView    *themeScrollView;    /*< 滚动视图 >*/
@property(nonatomic, strong) ThemeImageView  *selectedItem;       /*< 保存当前选择的项 >*/

/**
 *	@brief	加载所有的主题
 */
- (void)loadThemeImages;

/**
 *	@brief  改变主题选项
 */
- (void)changeItemStateToNormal;

@end


@implementation ThemeScrollView

- (void)dealloc
{
    if (_bgImageView)
    {
        [_bgImageView release];
        _bgImageView = nil;
    }
    
    if (_themeScrollView)
    {
        [_themeScrollView release];
        _themeScrollView = nil;
    }
    
    if (_selectedItem)
    {
        [_selectedItem release];
        _selectedItem = nil;
    }
    
    [super dealloc];
}

/**
 *	@brief	从xib加载视图
 */
- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initialize];
    [self setExclusiveTouch:YES];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        // Initialization code
        [self initialize];
    }
    return self;
}

/**
 *	@brief	初始化方法
 */
- (void)initialize
{
    // set background color to clear color
    [self setBackgroundColor:[UIColor clearColor]];
    
    // set gap between two theme image view
    self.themeHPadding  = THEME_H_PADDING;
    
    // set start position for first theme image view at X-axis
    self.startXPosition = THEME_H_START;
    
    NSMutableDictionary *themImagesArray = [[VideoThemesData sharedInstance] getThemeData];
    NSMutableArray *temp = [NSMutableArray array];
    for (int i = kThemeNone; i < [themImagesArray count]; ++i)
    {
        VideoThemes *material = [themImagesArray objectForKey:[NSNumber numberWithInt:i]];
        [temp addObject:material];
         material = nil;
    }
    
    self.themeImages = [temp copy];
    
    if (temp)
    {
        [temp removeAllObjects];
        temp = nil;
    }
}

/**
 *	@brief	更新主题数据源
 *
 *	@param 	themeImages 	所有新的主题
 */
- (void)setThemeImages:(NSMutableArray *)themeImages
{
    // 判断新旧主题是否一直
    if (themeImages == self.themeImages)
    {
        return;
    }
    
    // 移除所有的主题视图
    if (nil != _themeImages)
    {
        NSUInteger count = [_themeImages count];
        [self.themeImages  removeAllObjects];
        
        // release scroll view subviews
        for (int i = 0; i != count; ++i)
        {
            [[_themeScrollView viewWithTag:THEME_TAG_BASE + i] removeFromSuperview];
        }
    }
    
    _themeImages = themeImages;
    
    // load new imageView
    [self loadThemeImages];
}

/**
 *	@brief	设置主题间的间隔
 *
 *	@param 	themeHPadding 	主题间间隔
 */
- (void)setThemeHPadding:(CGFloat)themeHPadding
{
    NSInteger count  = [_themeImages count];
    CGFloat   addDis = 0.0f;
    
    if (count != 0)
    {
        CGFloat rise = themeHPadding - _themeHPadding;
        for (int i = 1; i != count; ++i)
        {
            ThemeImageView *themeView = (ThemeImageView *)[_themeScrollView viewWithTag:THEME_TAG_BASE + i];
            CGPoint centrePt = themeView.center;
            centrePt.x += (i * rise);
            themeView.center = centrePt;
        }
        
        CGSize contentSize = _themeScrollView.contentSize;
        addDis += (count * rise);
        [_themeScrollView setContentSize:CGSizeMake(contentSize.width + addDis,self.bounds.size.height)];
    }
    
    _themeHPadding = themeHPadding;
}

/**
 *	@brief	设置最后一个按钮
 *
 *	@param 	btnlastThemeCell{ 	设置最后一个按钮
 */
- (void)setBtnlastThemeCell:(UIButton *)btnlastThemeCell
{
    if (_btnlastThemeCell != btnlastThemeCell)
    {
        [_btnlastThemeCell removeFromSuperview];
        _btnlastThemeCell = btnlastThemeCell;
        
        NSInteger numOfTheme = [[self themeImages] count];
        
        CGFloat x = self.startXPosition + (self.selectedItem.frame.size.width + THEME_H_PADDING)*numOfTheme;
        CGFloat y = (self.themeScrollView.frame.size.height - btnlastThemeCell.frame.size.height)/2.0f;
        CGFloat width  = btnlastThemeCell.frame.size.width;
        CGFloat height = btnlastThemeCell.frame.size.height;
        
        CGRect  rect   = CGRectMake(x, y, width, height);
        _btnlastThemeCell.frame = rect;
        [_themeScrollView addSubview:_btnlastThemeCell];
        [_themeScrollView setContentSize:CGSizeMake(_themeScrollView.contentSize.width + _btnlastThemeCell.frame.size.width + THEME_H_PADDING,
                                                    _themeScrollView.contentSize.height)];
    }
}

#pragma mark - ThumbImageView delegate methods
- (void)themeImageViewWasTapped:(ThemeImageView *)themeImageView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(themeScrollView:didSelectMaterial:)])
    {
        [self changeItemStateToNormal];
        self.selectedItem = themeImageView;
        [self.delegate themeScrollView:self didSelectMaterial:[self.themeImages objectAtIndex:themeImageView.tag - THEME_TAG_BASE]];
    }
    else
    {
        [self changeItemStateToNormal];
        self.selectedItem = themeImageView;
        if ([self.delegate respondsToSelector:@selector(selectedItem:)])
        {
            [self.delegate selectedItem:themeImageView.tag - THEME_TAG_BASE];
        }
    }
}


#pragma mark - ViewHandingMethods
/**
 *	@brief	加载新的主题
 */
- (void)loadThemeImages
{
    CGRect  bound = self.bounds;
    CGFloat scrollViewHeight = bound.size.height;
    
    if (_themeScrollView ==  nil)
    {
        _themeScrollView = [[UIScrollView alloc] initWithFrame:bound];
        [self addSubview:_themeScrollView];
    }
    else
    {
        scrollViewHeight = _themeScrollView.frame.size.height;
    }
    
    [self.themeScrollView setCanCancelContentTouches:NO];
    [self.themeScrollView setClipsToBounds:YES];
    [self.themeScrollView setShowsHorizontalScrollIndicator:NO];
    [self.themeScrollView setShowsVerticalScrollIndicator:NO];
    
    CGFloat xPosition = self.startXPosition;
    CGFloat yPosition = 0;
    
    NSInteger index = 0;
    for (VideoThemes *matl in _themeImages)
    {
        NSString *text = nil;
        NSString *thumbImage = nil;
        if ((NSNull*)matl == [NSNull null])
        {
            text = @"Original";
            thumbImage = @"themeOriginal";
        }
        else
        {
            text = matl.name;
            thumbImage = matl.thumbImageName;
        }
        
//        NSString *imagePath  = [[NSBundle mainBundle] pathForResource:thumbImage ofType:nil];
//        UIImage  *themeImage = [UIImage imageWithContentsOfFile:imagePath];
//        if (nil != themeImage)
        {
            // 加载主题视图
            ThemeImageView *themeView = [[ThemeImageView alloc] initWithFrame:CGRectMake(0, 0, 72, 102)];
            themeView.themeName = text;
            themeView.thumbImageName = thumbImage;
            themeView.tag = THEME_TAG_BASE + index;
            [themeView setDelegate:self];
            
            CGRect rect = [themeView frame];
            yPosition = (scrollViewHeight - rect.size.height)/2.0f;
            rect.origin.y = yPosition;
            rect.origin.x = xPosition;
            [themeView setFrame:rect];
            [self.themeScrollView addSubview:themeView];
        
            xPosition += (rect.size.width + _themeHPadding);
            
            [themeView release];
             themeView = nil; 
        }
        ++index;
    }

     xPosition = xPosition > 320.0f ? xPosition : 320.0f;
    [self.themeScrollView setContentSize:CGSizeMake(xPosition, scrollViewHeight)];
}

- (CGPoint)getContentOffsetAtIndex:(int)index
{
	if (index < 0)
    {
		return CGPointMake(0.0f, 0.0f);
	}
	
	UIView *itemView = [self.themeScrollView viewWithTag:THEME_TAG_BASE + index];
	CGFloat y = itemView.frame.size.height;
	CGFloat x = _startXPosition + itemView.frame.origin.x;
	
	return CGPointMake(x, y);
}

- (void)setContentStartAtIndex:(int)index
{
	if (index < 0)
    {
		return;
	}
	
	UIView *itemView = [_themeScrollView viewWithTag: THEME_TAG_BASE + index];
	CGFloat y = 0;
	CGFloat x = _startXPosition + itemView.frame.origin.x - _themeHPadding;
	
	[self.themeScrollView setContentOffset: CGPointMake(x, y) animated: YES];
}

- (void)setContentEndAtIndex:(int)index
{
	if (index < 0)
    {
		return;
	}
	
	UIView *itemView = [self.themeScrollView  viewWithTag: THEME_TAG_BASE + index];
	CGFloat y = 0.0f;
	CGFloat x = itemView.frame.origin.x + itemView.frame.size.width + _themeHPadding;
	
	x -= 320.0f;	// 判断是否超出屏幕范围
	
	if (x > 0.0f)
    {
		// 需要显示的内容超过屏幕宽度的时候
	}
    else
    {
		// 内容还没达到一个屏幕宽度的时候
		x = 0.0f;
	}
	
	[self.themeScrollView  setContentOffset: CGPointMake(x, y) animated: YES];
}

- (void)changeItemStateToNormal
{
	if (_selectedItem == nil)
    {
		return;
	}
    else
    {
		[_selectedItem selected:NO];
	}
}

- (void)setCurrentSelectedItem: (NSInteger) index
{
	if (index == -1)
    {
		return;
	}
    
	ThemeImageView* tmp = (ThemeImageView*) [_themeScrollView viewWithTag:THEME_TAG_BASE + index];
    _selectedItem = tmp;
    [_selectedItem selected:YES];
    
    if (!tmp)
    {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(themeScrollView:didSelectMaterial:)])
    {
        [self.delegate themeScrollView:self
                     didSelectMaterial:[self.themeImages objectAtIndex:tmp.tag - THEME_TAG_BASE]];
    }
}

- (void)scrollToItemAtIndex:(NSInteger)index
{
	if (index<0 || index >= [_themeImages count])
        return;	// 不符合索引直接返回
	
	UIView *itemView = [_themeScrollView viewWithTag:THEME_TAG_BASE + index];
	CGRect rect = itemView.frame;
	CGSize contentSize = [_themeScrollView contentSize];	// 内容大小
	CGPoint contentOffset = [_themeScrollView contentOffset];	// 当前偏移值
	CGFloat x = rect.origin.x;
    
	if (x < contentOffset.x)
    {
		// 在屏幕范围的外面
		x -= _startXPosition;
	}
    else if (x > contentOffset.x+320)
    {
		// 要显示的节点在屏幕外
		if (index == ([_themeImages count] - 1))
        {
			// 是最后一个节点
			x = contentSize.width - 320;
		}
        else
        {
			// 将当前的节点做为最后一个节点显示完整的节点
			x -= (_startXPosition + (rect.size.width+_themeHPadding)*3);
		}
	}
    else
    {
		// 在屏幕可显示范围内
		CGFloat showAllItemWith = _startXPosition + (rect.size.width+_themeHPadding)*3 + rect.size.width;	// 完整显示的4个节点宽度
		if ((x - contentOffset.x) <= showAllItemWith)
        {
			// 位置不到一个屏幕的时候不做移动
			return;
		}
		
		if (index == ([_themeImages count] - 1))
        {
			// 是最后一个节点
			x = contentSize.width - 320;
		}
        else
        {
			// 将当前的节点做为最后一个节点显示完整的节点
			x -= (_startXPosition + (rect.size.width+_themeHPadding)*3);
		}
	}
    
	[_themeScrollView setContentOffset: CGPointMake(x, 0.0f) animated: YES];
}

@end