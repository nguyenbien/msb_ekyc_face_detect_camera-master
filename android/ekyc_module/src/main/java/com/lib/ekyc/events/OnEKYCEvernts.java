package com.lib.ekyc.events;

import com.lib.ekyc.misc.DetectionEvent;

public interface OnEKYCEvernts {
   void detectionEvents(DetectionEvent var1, String var2);

   void onGestreDetectinCompleted(boolean var1, String var2);
}
