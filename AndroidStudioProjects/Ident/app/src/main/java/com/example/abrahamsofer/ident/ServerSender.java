package com.example.abrahamsofer.ident;

import android.app.ProgressDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;

import org.apache.commons.io.FileUtils;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.UnsupportedEncodingException;

import javax.net.ssl.HttpsURLConnection;

/**
 * Created by abrahamsofer on 16/08/2016.
 */
public class ServerSender extends AsyncTask<File, Void, Void> {

    private String server;
    private String pin;
    private String price;

    public ServerSender(final String server, String pin, String price) {
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


    @Override
    protected Void doInBackground(File... data) {

        //  String url = "http://localhost:52531/";


        File file = data[0];
        byte bytes[] = new byte[0];
        try {
            bytes = FileUtils.readFileToByteArray(file);
        } catch (IOException e) {
            e.printStackTrace();
        }

        ////
        Bitmap bm = BitmapFactory.decodeFile(file.getPath());
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bm.compress(Bitmap.CompressFormat.JPEG, 100, baos); //bm is the bitmap object
        byte[] b = baos.toByteArray();
        String encodedImage = Base64.encodeToString(b, Base64.DEFAULT);
        ////

        JSONObject json = new JSONObject();
        try {
            json.put("Pin",pin);
            //json.put("Image",b);
            json.put("Image",encodedImage);
            //json.put("Image", Base64.encode(bytes,0));

            StringEntity se = new StringEntity(json.toString());
            HttpClient httpclient = new DefaultHttpClient();
            HttpPost httpPost = new HttpPost(this.server);
            httpPost.setEntity(se);
            httpPost.setHeader("Accept", "application/json");
            httpPost.setHeader("Content-type", "application/json");
            HttpResponse response;
            try {
                response = httpclient.execute(httpPost);
            }
            catch(Exception e) {
                response = null;
            }


        } catch (JSONException e) {
            e.printStackTrace();
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }  catch (IOException e) {
            e.printStackTrace();
        }

             /*
			try {
				HttpClient httpclient = new DefaultHttpClient();
				HttpPost httppost = new HttpPost(this.server);
				InputStreamEntity reqEntity = new InputStreamEntity(
						new FileInputStream(file), -1);
				reqEntity.setContentType("binary/octet-stream");
				reqEntity.setChunked(true); // Send in multiple parts if needed
				httppost.setEntity(reqEntity);
				HttpResponse response = httpclient.execute(httppost);
				//Do something with response...
			} catch (Exception e) {
				// show error
			}*/
        finally {
        }
        return null;
    }
    public void sendFile(File file) {
        new ServerSender(server, pin, price).execute(file);
    }

}