package com.example.abrahamsofer.ident;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

/**
 * Created by abrahamsofer on 18/08/2016.
 */
public class SuccessActivity extends Activity {


    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_success);

        TextView text  = (TextView) findViewById(R.id.editText6);
        TextView order  = (TextView) findViewById(R.id.editText4);
        Bundle b = this.getIntent().getExtras();
        String name = b.getString("name");
        text.setText("Hi " + name.toString()+ ",");
        if(b.containsKey("orderID") ) {
            String orderID = b.getString("orderID");
            if(!orderID.isEmpty()){
                order.setText("order # " + orderID);
            }
        }
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
