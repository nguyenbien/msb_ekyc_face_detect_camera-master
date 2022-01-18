package com.lib.ekyc.entity;

import androidx.annotation.Keep;
import com.lib.ekyc.core.ekyc.CameraSource;
import java.util.List;

@Keep
public class DetectionParams {
   private List<Gesture> gestureList;
   private long minGestureDetectionTime = 30000L;
   private GestureConstants gestureConstants = new GestureConstants();
   private String imageFileName;
   private String videoFileName;
   private CameraSource cameraSource;

   public List<Gesture> getGestureList() {
      return this.gestureList;
   }

   public long getMinGestureDetectionTime() {
      return this.minGestureDetectionTime;
   }

   public GestureConstants getGestureConstants() {
      return this.gestureConstants;
   }

   public String getImageFileName() {
      return this.imageFileName;
   }

   public String getVideoFileName() {
      return this.videoFileName;
   }

   public CameraSource getCameraSource() {
      return this.cameraSource;
   }

   public void setGestureList(List<Gesture> gestureList) {
      this.gestureList = gestureList;
   }

   public void setMinGestureDetectionTime(long minGestureDetectionTime) {
      this.minGestureDetectionTime = minGestureDetectionTime;
   }

   public void setGestureConstants(GestureConstants gestureConstants) {
      this.gestureConstants = gestureConstants;
   }

   public void setImageFileName(String imageFileName) {
      this.imageFileName = imageFileName;
   }

   public void setVideoFileName(String videoFileName) {
      this.videoFileName = videoFileName;
   }

   public void setCameraSource(CameraSource cameraSource) {
      this.cameraSource = cameraSource;
   }

   public boolean equals(Object o) {
      if (o == this) {
         return true;
      } else if (!(o instanceof DetectionParams)) {
         return false;
      } else {
         DetectionParams other = (DetectionParams)o;
         if (!other.canEqual(this)) {
            return false;
         } else {
            label75: {
               Object this$gestureList = this.getGestureList();
               Object other$gestureList = other.getGestureList();
               if (this$gestureList == null) {
                  if (other$gestureList == null) {
                     break label75;
                  }
               } else if (this$gestureList.equals(other$gestureList)) {
                  break label75;
               }

               return false;
            }

            if (this.getMinGestureDetectionTime() != other.getMinGestureDetectionTime()) {
               return false;
            } else {
               Object this$gestureConstants = this.getGestureConstants();
               Object other$gestureConstants = other.getGestureConstants();
               if (this$gestureConstants == null) {
                  if (other$gestureConstants != null) {
                     return false;
                  }
               } else if (!this$gestureConstants.equals(other$gestureConstants)) {
                  return false;
               }

               label60: {
                  Object this$imageFileName = this.getImageFileName();
                  Object other$imageFileName = other.getImageFileName();
                  if (this$imageFileName == null) {
                     if (other$imageFileName == null) {
                        break label60;
                     }
                  } else if (this$imageFileName.equals(other$imageFileName)) {
                     break label60;
                  }

                  return false;
               }

               Object this$videoFileName = this.getVideoFileName();
               Object other$videoFileName = other.getVideoFileName();
               if (this$videoFileName == null) {
                  if (other$videoFileName != null) {
                     return false;
                  }
               } else if (!this$videoFileName.equals(other$videoFileName)) {
                  return false;
               }

               Object this$cameraSource = this.getCameraSource();
               Object other$cameraSource = other.getCameraSource();
               if (this$cameraSource == null) {
                  if (other$cameraSource != null) {
                     return false;
                  }
               } else if (!this$cameraSource.equals(other$cameraSource)) {
                  return false;
               }

               return true;
            }
         }
      }
   }

   protected boolean canEqual(Object other) {
      return other instanceof DetectionParams;
   }

   public int hashCode() {
      boolean PRIME = true;
      int result = 1;
      Object $gestureList = this.getGestureList();
      result = result * 59 + ($gestureList == null ? 43 : $gestureList.hashCode());
      long $minGestureDetectionTime = this.getMinGestureDetectionTime();
      result = result * 59 + (int)($minGestureDetectionTime >>> 32 ^ $minGestureDetectionTime);
      Object $gestureConstants = this.getGestureConstants();
      result = result * 59 + ($gestureConstants == null ? 43 : $gestureConstants.hashCode());
      Object $imageFileName = this.getImageFileName();
      result = result * 59 + ($imageFileName == null ? 43 : $imageFileName.hashCode());
      Object $videoFileName = this.getVideoFileName();
      result = result * 59 + ($videoFileName == null ? 43 : $videoFileName.hashCode());
      Object $cameraSource = this.getCameraSource();
      result = result * 59 + ($cameraSource == null ? 43 : $cameraSource.hashCode());
      return result;
   }

   public String toString() {
      return "DetectionParams(gestureList=" + this.getGestureList() + ", minGestureDetectionTime=" + this.getMinGestureDetectionTime() + ", gestureConstants=" + this.getGestureConstants() + ", imageFileName=" + this.getImageFileName() + ", videoFileName=" + this.getVideoFileName() + ", cameraSource=" + this.getCameraSource() + ")";
   }
}
