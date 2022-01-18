package com.lib.ekyc.entity;

import androidx.annotation.Keep;

@Keep
public class GestureConstants {
   private int minAngle = 40;
   private float mouthOpenProbability = 0.4F;
   private float eyeOpenProbability = 0.4F;

   public int getMinAngle() {
      return this.minAngle;
   }

   public float getMouthOpenProbability() {
      return this.mouthOpenProbability;
   }

   public float getEyeOpenProbability() {
      return this.eyeOpenProbability;
   }

   public void setMinAngle(int minAngle) {
      this.minAngle = minAngle;
   }

   public void setMouthOpenProbability(float mouthOpenProbability) {
      this.mouthOpenProbability = mouthOpenProbability;
   }

   public void setEyeOpenProbability(float eyeOpenProbability) {
      this.eyeOpenProbability = eyeOpenProbability;
   }

   public boolean equals(Object o) {
      if (o == this) {
         return true;
      } else if (!(o instanceof GestureConstants)) {
         return false;
      } else {
         GestureConstants other = (GestureConstants)o;
         if (!other.canEqual(this)) {
            return false;
         } else if (this.getMinAngle() != other.getMinAngle()) {
            return false;
         } else if (Float.compare(this.getMouthOpenProbability(), other.getMouthOpenProbability()) != 0) {
            return false;
         } else {
            return Float.compare(this.getEyeOpenProbability(), other.getEyeOpenProbability()) == 0;
         }
      }
   }

   protected boolean canEqual(Object other) {
      return other instanceof GestureConstants;
   }

   public int hashCode() {
      boolean PRIME = true;
      int result = 1;
      result = result * 59 + this.getMinAngle();
      result = result * 59 + Float.floatToIntBits(this.getMouthOpenProbability());
      result = result * 59 + Float.floatToIntBits(this.getEyeOpenProbability());
      return result;
   }

   public String toString() {
      return "GestureConstants(minAngle=" + this.getMinAngle() + ", mouthOpenProbability=" + this.getMouthOpenProbability() + ", eyeOpenProbability=" + this.getEyeOpenProbability() + ")";
   }
}
