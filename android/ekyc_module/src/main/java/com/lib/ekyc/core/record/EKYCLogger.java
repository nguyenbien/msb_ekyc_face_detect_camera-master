package com.lib.ekyc.core.record;

import android.util.Log;

public class EKYCLogger {
   public static void print(String TAG, String msg) {
      Log.d(TAG, "EKYC logger : " + msg);
   }

   public static void printe(String TAG, String msg) {
      Log.e(TAG, "EKYC logger : " + msg);
   }
}
