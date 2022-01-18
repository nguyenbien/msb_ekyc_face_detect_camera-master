package com.lib.ekyc.entity;

import androidx.annotation.Keep;

@Keep
public class Gesture {
   String name;
   long time;
   long start_time;
   long end_time;
   boolean status = false;

   public Gesture() {
   }

   public Gesture(String name, long time, long start_time, long end_time) {
      this.name = name;
      this.time = time;
      this.start_time = start_time;
      this.end_time = end_time;
   }

   public String getName() {
      return this.name;
   }

   public long getTime() {
      return this.time;
   }

   public long getStart_time() {
      return this.start_time;
   }

   public long getEnd_time() {
      return this.end_time;
   }

   public boolean isStatus() {
      return this.status;
   }

   public void setName(String name) {
      this.name = name;
   }

   public void setTime(long time) {
      this.time = time;
   }

   public void setStart_time(long start_time) {
      this.start_time = start_time;
   }

   public void setEnd_time(long end_time) {
      this.end_time = end_time;
   }

   public void setStatus(boolean status) {
      this.status = status;
   }

   public boolean equals(Object o) {
      if (o == this) {
         return true;
      } else if (!(o instanceof Gesture)) {
         return false;
      } else {
         Gesture other = (Gesture)o;
         if (!other.canEqual(this)) {
            return false;
         } else {
            Object this$name = this.getName();
            Object other$name = other.getName();
            if (this$name == null) {
               if (other$name != null) {
                  return false;
               }
            } else if (!this$name.equals(other$name)) {
               return false;
            }

            if (this.getTime() != other.getTime()) {
               return false;
            } else if (this.getStart_time() != other.getStart_time()) {
               return false;
            } else if (this.getEnd_time() != other.getEnd_time()) {
               return false;
            } else if (this.isStatus() != other.isStatus()) {
               return false;
            } else {
               return true;
            }
         }
      }
   }

   protected boolean canEqual(Object other) {
      return other instanceof Gesture;
   }

   public int hashCode() {
      boolean PRIME = true;
      int result = 1;
      Object $name = this.getName();
      result = result * 59 + ($name == null ? 43 : $name.hashCode());
      long $time = this.getTime();
      result = result * 59 + (int)($time >>> 32 ^ $time);
      long $start_time = this.getStart_time();
      result = result * 59 + (int)($start_time >>> 32 ^ $start_time);
      long $end_time = this.getEnd_time();
      result = result * 59 + (int)($end_time >>> 32 ^ $end_time);
      result = result * 59 + (this.isStatus() ? 79 : 97);
      return result;
   }

   public String toString() {
      return "Gesture(name=" + this.getName() + ", time=" + this.getTime() + ", start_time=" + this.getStart_time() + ", end_time=" + this.getEnd_time() + ", status=" + this.isStatus() + ")";
   }
}
