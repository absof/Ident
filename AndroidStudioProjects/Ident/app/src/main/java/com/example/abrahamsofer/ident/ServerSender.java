package com.example.abrahamsofer.ident;

import android.app.Activity;
import android.app.DownloadManager;
import android.app.ProgressDialog;
//import android.content.Intent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;

import org.apache.commons.io.FileUtils;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;



import java.io.IOException;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.ResponseBody;

/**
 * Created by abrahamsofer on 16/08/2016.
 */
public class ServerSender extends AsyncTask<File, Void, Void> {

    private String server;
    private String pin;
    private String price;
    private Context context;
    public ServerSender(Context context,final String server, String pin, String price) {
        this.context = context;
        this.server = server;
        this.pin = pin;
        this.price = price;
    }

    public boolean upload(File file) {
        Log.e("path", "----------------" + file);

        // Image
        Bitmap bm = BitmapFactory.decodeFile(file.toString());
        ByteArrayOutputStream bao = new ByteArrayOutputStream();
        bm.compress(Bitmap.CompressFormat.JPEG, 90, bao);
        byte[] ba = bao.toByteArray();
        //ba1 = Base64.encodeBytes(ba);

        //Log.e("base64", "-----" + ba1);

        // Upload image to server
        // new ServerSender().execute();

        return false;
    }

    public static MediaType JSON = MediaType.parse("application/json; charset=utf-8");

    public static OkHttpClient client = new OkHttpClient();

    public static String post(String url, String json) throws Exception {
        RequestBody body = RequestBody.create(JSON, json);
        Request request = new Request.Builder()
                .url(url)
                .post(body)
                .build();
        String resString = null;
        try {
            Response response = client.newCall(request).execute();

            ResponseBody responseBody = response.body();

            resString = responseBody.string().toString();

        }
        catch(Exception E){
            return null;
        }
        return resString;

    }

    public static float getDegree(String exifOrientation) {
        float degree = 0;
        if (exifOrientation.equals("6"))
            degree = 90;
        else if (exifOrientation.equals("3"))
            degree = 180;
        else if (exifOrientation.equals("8"))
            degree = 270;
        return degree;
    }
    public static Bitmap createRotatedBitmap(Bitmap bm, float degree) {
        Bitmap bitmap = null;
        if (degree != 0) {
            Matrix matrix = new Matrix();
            matrix.preRotate(degree);
            bitmap = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(),
                    bm.getHeight(), matrix, true);
        }

        return bitmap;
    }


    @Override
    protected Void doInBackground(File... data) {

        File file = data[0];
        byte bytes[] = new byte[0];
        try {
            bytes = FileUtils.readFileToByteArray(file);
        } catch (IOException e) {
            e.printStackTrace();
        }




        BitmapFactory.Options opts = new BitmapFactory.Options();
        Bitmap bm = BitmapFactory.decodeFile(file.getPath(),opts);

        float degree = 0;
        ExifInterface exif = null;
        try {
            exif = new ExifInterface(file.getPath());
            String exifOrientation = exif.getAttribute(ExifInterface.TAG_ORIENTATION);
            degree = getDegree(exifOrientation);
            if(degree != 0)
                bm = createRotatedBitmap(bm, degree);
        } catch (IOException e) {
            e.printStackTrace();
        }

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
       // 0-100. 0 meaning compress for small size, 100 meaning compress for max quality
        bm.compress(Bitmap.CompressFormat.JPEG, 80, baos); //bm is the bitmap object
        byte[] b = baos.toByteArray();
        String encodedImage = Base64.encodeToString(b, Base64.DEFAULT);
        String response = null;
        JSONObject json = new JSONObject();
        try {
            json.put("Pin", pin);
            json.put("Image", encodedImage);
            String jsonStr = json.toString();
            response =  ServerSender.post(this.server,jsonStr);
            if(response != null) {
                JSONObject jsonRes  = new JSONObject(response);
                Bundle userData = new Bundle();
                userData.putString("name",jsonRes.getString("FirstName"));
                userData.putString("email",jsonRes.getString("Email"));

                if(!jsonRes.isNull("orderID"))
                    userData.putString("orderID",jsonRes.getString("orderID"));
                //userData.putString("orderID","12345");

                Intent in  = new Intent(context,QuestionActivity.class);
                in.putExtras(userData);
                this.context.startActivity(in);
                ((Activity)this.context).finish();

            }
            else {
                throw new Exception();
            }
        }
        catch(Exception e) {
            Intent in  = new Intent(context,FailActivity.class);
            context.startActivity(in);
            ((Activity)context).finish();
        }
        finally {
            try{
                baos.close();
            }
            catch (Exception e){};
        }
      return null;
    }


    public void sendFile(Context c,File file) {
        new ServerSender(c,server, pin, price).execute(file);
    }



}