package com.airbnb.android.react.maps;

import android.content.Context;

import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.model.TileOverlay;
import com.google.android.gms.maps.model.TileOverlayOptions;
import com.google.android.gms.maps.model.UrlTileProvider;

import java.net.MalformedURLException;
import java.net.URL;

public class AirMapUrlTile extends AirMapFeature {
  private static final double[] mapBound = {-20037508.34789244, 20037508.34789244};
  private static final double FULL = 20037508.34789244 * 2;

  class AIRMapUrlTileProvider extends UrlTileProvider {
    private String urlTemplate;
    private int width;
    private int height;

    public AIRMapUrlTileProvider(int width, int height, String urlTemplate) {
      super(width, height);
      this.urlTemplate = urlTemplate;
    }

    private double convertY(int y, int zoom) {
      double scale = Math.pow(2.0, zoom);
      double n = Math.PI - (2.0 * Math.PI * y ) / scale;
      return  Math.atan(Math.sinh(n)) * 180 / Math.PI;
    }

    private double[] getBoundingBox(int x, int y, int zoom) {
      double scale = Math.pow(2.0, zoom);

      double x1 = x/scale * 360 - 180;
      double x2 = (x+1)/scale * 360 - 180;

      double y1 = convertY(y+1,zoom);
      double y2 = convertY(y,zoom);

      return new double[]{
              x1,
              y1,
              x2,
              y2
      };
    }

    @Override
    public synchronized URL getTileUrl(int x, int y, int zoom) {
      Boolean isWMS = false;
      if (this.urlTemplate.length() > 4) {
        if (this.urlTemplate.substring(this.urlTemplate.length() - 5).equals("{WMS}")) {
          isWMS = true;
        }
      }

      if (isWMS) {
        double[] bb = getBoundingBox(x, y, zoom);
        String s = this.urlTemplate
                .replace("{minX}", Double.toString(bb[0]))
                .replace("{minY}", Double.toString(bb[1]))
                .replace("{maxX}", Double.toString(bb[2]))
                .replace("{maxY}", Double.toString(bb[3]))
                .replace("{width}", Integer.toString(1024))
                .replace("{height}", Integer.toString(1024))
                .replace("{WMS}", "");

        URL url = null;
        try {
          url = new URL(s);
        } catch (MalformedURLException e) {
          throw new AssertionError(e);
        }
        return url;
      } else {
        if (AirMapUrlTile.this.flipY) {
          y = (1 << zoom) - y - 1;
        }

        String s = this.urlTemplate
                .replace("{x}", Integer.toString(x))
                .replace("{y}", Integer.toString(y))
                .replace("{z}", Integer.toString(zoom));
        URL url = null;

        if (AirMapUrlTile.this.maximumZ > 0 && zoom > maximumZ) {
          return url;
        }

        if (AirMapUrlTile.this.minimumZ > 0 && zoom < minimumZ) {
          return url;
        }

        try {
          url = new URL(s);
        } catch (MalformedURLException e) {
          throw new AssertionError(e);
        }
        return url;
      }
    }

    public void setUrlTemplate(String urlTemplate) {
      this.urlTemplate = urlTemplate;
    }
  }

  private TileOverlayOptions tileOverlayOptions;
  private TileOverlay tileOverlay;
  private AIRMapUrlTileProvider tileProvider;

  private String urlTemplate;
  private float zIndex;
  private float maximumZ;
  private float minimumZ;
  private boolean flipY;

  public AirMapUrlTile(Context context) {
    super(context);
  }

  public void setUrlTemplate(String urlTemplate) {
    this.urlTemplate = urlTemplate;
    if (tileProvider != null) {
      tileProvider.setUrlTemplate(urlTemplate);
    }
    if (tileOverlay != null) {
      tileOverlay.clearTileCache();
    }
  }

  public void setZIndex(float zIndex) {
    this.zIndex = zIndex;
    if (tileOverlay != null) {
      tileOverlay.setZIndex(zIndex);
    }
  }

  public void setMaximumZ(float maximumZ) {
    this.maximumZ = maximumZ;
    if (tileOverlay != null) {
      tileOverlay.clearTileCache();
    }
  }

  public void setMinimumZ(float minimumZ) {
    this.minimumZ = minimumZ;
    if (tileOverlay != null) {
      tileOverlay.clearTileCache();
    }
  }

  public void setFlipY(boolean flipY) {
    this.flipY = flipY;
    if (tileOverlay != null) {
      tileOverlay.clearTileCache();
    }
  }

  public TileOverlayOptions getTileOverlayOptions() {
    if (tileOverlayOptions == null) {
      tileOverlayOptions = createTileOverlayOptions();
    }
    return tileOverlayOptions;
  }

  private TileOverlayOptions createTileOverlayOptions() {
    TileOverlayOptions options = new TileOverlayOptions();
    options.zIndex(zIndex);
    this.tileProvider = new AIRMapUrlTileProvider(256, 256, this.urlTemplate);
    options.tileProvider(this.tileProvider);
    return options;
  }

  @Override
  public Object getFeature() {
    return tileOverlay;
  }

  @Override
  public void addToMap(GoogleMap map) {
    this.tileOverlay = map.addTileOverlay(getTileOverlayOptions());
  }

  @Override
  public void removeFromMap(GoogleMap map) {
    tileOverlay.remove();
  }
}
