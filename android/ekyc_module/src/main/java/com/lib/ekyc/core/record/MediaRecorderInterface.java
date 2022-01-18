package com.lib.ekyc.core.record;

import android.content.Context;
import com.lib.ekyc.core.ekyc.OnRecorderEvents;

public interface MediaRecorderInterface {
   void initRecorder(Context var1);

   void startRecording();

   void stopRecording(OnRecorderEvents var1);

   void onFrame(byte[] var1, int var2, int var3, int var4);
}
