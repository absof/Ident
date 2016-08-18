package com.example.abrahamsofer.ident;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

/**
 * Created by abrahamsofer on 18/08/2016.
 */
public class SuccessActivity extends Activity {


    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_success);
        Button okay  = (Button) findViewById(R.id.button33);
        okay.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                Intent in  = new Intent(getApplicationContext(),CameraActivity.class);
                startActivity(in);
                finish();

            }
        });

    }



}
