package com.lib.ekyc.core.record;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

public class SaveImageUtil {
   private static final String TAG = "SaveImageUtil";

   public static File saveBitmap(Context context, Bitmap bitmap) {
      ByteArrayOutputStream stream = new ByteArrayOutputStream();
      bitmap.compress(CompressFormat.JPEG, 100, stream);
      File file = null;

      try {
         file = createFile(context);
         OutputStream outputStream = new FileOutputStream(file);
         stream.writeTo(outputStream);
         stream.close();
         outputStream.close();
         EKYCLogger.print("SaveImageUtil", "file saved to path : " + file.getAbsolutePath());
      } catch (FileNotFoundException var5) {
         var5.printStackTrace();
      } catch (IOException var6) {
         var6.printStackTrace();
      }

      return file;
   }

   private static File createFile(Context context) {
      File file = null;

      try {
         String sdcardroot = context.getFilesDir().getAbsolutePath();
         EKYCLogger.print("SaveImageUtil", "createFile: jpeg " + sdcardroot);
         String mFileName = System.currentTimeMillis() + ".jpeg";
         file = new File(sdcardroot, mFileName);
      } catch (Exception var4) {
         var4.printStackTrace();
      }

      return file;
   }
}
