package com.lib.ekyc.entity;

import androidx.annotation.Keep;
import java.util.List;

@Keep
public class GestureData {
   private String video_file;
   private String image_file;
   private List<Gesture> meta_data;

   public String getVideo_file() {
      return this.video_file;
   }

   public String getImage_file() {
      return this.image_file;
   }

   public List<Gesture> getMeta_data() {
      return this.meta_data;
   }

   public void setVideo_file(String video_file) {
      this.video_file = video_file;
   }

   public void setImage_file(String image_file) {
      this.image_file = image_file;
   }

   public void setMeta_data(List<Gesture> meta_data) {
      this.meta_data = meta_data;
   }

   public boolean equals(Object o) {
      if (o == this) {
         return true;
      } else if (!(o instanceof GestureData)) {
         return false;
      } else {
         GestureData other = (GestureData)o;
         if (!other.canEqual(this)) {
            return false;
         } else {
            label47: {
               Object this$video_file = this.getVideo_file();
               Object other$video_file = other.getVideo_file();
               if (this$video_file == null) {
                  if (other$video_file == null) {
                     break label47;
                  }
               } else if (this$video_file.equals(other$video_file)) {
                  break label47;
               }

               return false;
            }

            Object this$image_file = this.getImage_file();
            Object other$image_file = other.getImage_file();
            if (this$image_file == null) {
               if (other$image_file != null) {
                  return false;
               }
            } else if (!this$image_file.equals(other$image_file)) {
               return false;
            }

            Object this$meta_data = this.getMeta_data();
            Object other$meta_data = other.getMeta_data();
            if (this$meta_data == null) {
               if (other$meta_data != null) {
                  return false;
               }
            } else if (!this$meta_data.equals(other$meta_data)) {
               return false;
            }

            return true;
         }
      }
   }

   protected boolean canEqual(Object other) {
      return other instanceof GestureData;
   }

   public int hashCode() {
      boolean PRIME = true;
      int result = 1;
      Object $video_file = this.getVideo_file();
      result = result * 59 + ($video_file == null ? 43 : $video_file.hashCode());
      Object $image_file = this.getImage_file();
      result = result * 59 + ($image_file == null ? 43 : $image_file.hashCode());
      Object $meta_data = this.getMeta_data();
      result = result * 59 + ($meta_data == null ? 43 : $meta_data.hashCode());
      return result;
   }

   public String toString() {
      return "GestureData(video_file=" + this.getVideo_file() + ", image_file=" + this.getImage_file() + ", meta_data=" + this.getMeta_data() + ")";
   }
}
