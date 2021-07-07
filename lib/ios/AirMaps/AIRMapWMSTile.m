//
//  AIRMapWMSTile.m
//  AirMaps
//
//  Created by nizam on 10/28/18.
//  Copyright © 2018. All rights reserved.
//

#import "AIRMapWMSTile.h"
#import <React/UIView+React.h>

@implementation AIRMapWMSTile {
    BOOL _urlTemplateSet;
}

- (void)setShouldReplaceMapContent:(BOOL)shouldReplaceMapContent
{
  _shouldReplaceMapContent = shouldReplaceMapContent;
  if(self.tileOverlay) {
    self.tileOverlay.canReplaceMapContent = _shouldReplaceMapContent;
  }
  [self update];
}

- (void)setMaximumZ:(NSUInteger)maximumZ
{
  _maximumZ = maximumZ;
  if(self.tileOverlay) {
    self.tileOverlay.maximumZ = _maximumZ;
  }
  [self update];
}

- (void)setMinimumZ:(NSUInteger)minimumZ
{
  _minimumZ = minimumZ;
  if(self.tileOverlay) {
    self.tileOverlay.minimumZ = _minimumZ;
  }
  [self update];
}

- (void)setTileSize:(NSInteger)tileSize
{
    _tileSize = tileSize;
    if(self.tileOverlay) {
        self.tileOverlay.tileSize = CGSizeMake(tileSize, tileSize);
    }
    [self update];
}
- (void)setUrlTemplate:(NSString *)urlTemplate{
    _urlTemplate = urlTemplate;
    _urlTemplateSet = YES;
    [self createTileOverlayAndRendererIfPossible];
    [self update];
}

- (void) createTileOverlayAndRendererIfPossible
{
    if (!_urlTemplateSet) return;
    self.tileOverlay  = [[TileOverlay alloc] initWithURLTemplate:self.urlTemplate];
    self.tileOverlay.canReplaceMapContent = self.shouldReplaceMapContent;

    if(self.minimumZ) {
        self.tileOverlay.minimumZ = self.minimumZ;
    }
    if (self.maximumZ) {
        self.tileOverlay.maximumZ = self.maximumZ;
    }
    if (self.tileSize) {
        self.tileOverlay.tileSize = CGSizeMake(self.tileSize, self.tileSize);;
    }
    self.renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:self.tileOverlay];
}

- (void) update
{
    if (!_renderer) return;

    if (_map == nil) return;
    [_map removeOverlay:self];
    [_map addOverlay:self level:MKOverlayLevelAboveLabels];
    for (id<MKOverlay> overlay in _map.overlays) {
        if ([overlay isKindOfClass:[AIRMapWMSTile class]]) {
            continue;
        }
        [_map removeOverlay:overlay];
        [_map addOverlay:overlay];
    }
}

#pragma mark MKOverlay implementation

- (CLLocationCoordinate2D) coordinate
{
    return self.tileOverlay.coordinate;
}

- (MKMapRect) boundingMapRect
{
    return self.tileOverlay.boundingMapRect;
}

- (BOOL)canReplaceMapContent
{
    return self.tileOverlay.canReplaceMapContent;
}

@end

@implementation TileOverlay
@synthesize MapX;
@synthesize MapY;
@synthesize FULL;

-(id) initWithURLTemplate:(NSString *)URLTemplate {
    self = [super initWithURLTemplate:URLTemplate];
    MapX = -20037508.34789244;
    MapY = 20037508.34789244;
    FULL = 20037508.34789244 * 2;
    return self ;
}

-(NSURL *)URLForTilePath:(MKTileOverlayPath)path{
    NSArray *bb = [self getBoundBox:path.x yAxis:path.y zoom:path.z];
    NSMutableString *url = [self.URLTemplate mutableCopy];
    [url replaceOccurrencesOfString: @"{minX}" withString:[NSString stringWithFormat:@"%@", bb[0]] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{minY}" withString:[NSString stringWithFormat:@"%@", bb[1]] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{maxX}" withString:[NSString stringWithFormat:@"%@", bb[2]] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{maxY}" withString:[NSString stringWithFormat:@"%@", bb[3]] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{width}" withString:[NSString stringWithFormat:@"%d", (int)self.tileSize.width] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{height}" withString:[NSString stringWithFormat:@"%d", (int)self.tileSize.height] options:0 range:NSMakeRange(0, url.length)];
    return [NSURL URLWithString:url];
}

-(double) convertY:(int) y Zoom:(int) zoom  {
    double scale = pow(2.0, zoom);
    double n = M_PI - (2.0 * M_PI * y ) / scale;
    return  atan(sinh(n)) * 180 / M_PI;
}

-(NSArray *)getBoundBox:(NSInteger)x yAxis:(NSInteger)y zoom:(NSInteger)zoom{
    double scale = pow(2.0, zoom);

    double x1 = x/scale * 36;
    double x2 = (x+1)/scale * 36;

    double y1 = [self convertY:(double)(y+1) Zoom:(double)zoom];
    double y2 = [self convertY:(double)(y) Zoom:(double)zoom];

    NSArray *result  =[[NSArray alloc] initWithObjects:
                       [NSNumber numberWithDouble:x1 ],
                       [NSNumber numberWithDouble:y1 ],
                       [NSNumber numberWithDouble:x2 ],
                       [NSNumber numberWithDouble:y2 ],
                       nil];

    return result;
}
@end
