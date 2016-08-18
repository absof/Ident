package com.example.abrahamsofer.ident;

import android.app.Activity;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.TextView;
import android.widget.Toast;

/**
 * Created by abrahamsofer on 18/08/2016.
 */
public class QuestionActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_question);
        TextView question = (TextView) findViewById(R.id.questionText);
        question.setText("Hello " + getClientData().get("userFullName") + ", enter your email " +
                "address to confirm your Identitiy ");

        final EditText editText = (EditText) findViewById(R.id.answerText);
        editText.setHint("Enter email");

        ImageButton button = (ImageButton) findViewById(R.id.confirm);
        button.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View arg0) {
                String email = editText.getText().toString();
                if (email == null) {
                    Toast.makeText(getBaseContext(),"Please enter your email address",Toast.LENGTH_SHORT).show();
                }else if(email == getClientData().getString("clientEmail")) {
                    // Launch Success Activity
                }else{
                    //Lauch FailActivity
                }



			}
		});


        if (null == savedInstanceState) {
            getFragmentManager().beginTransaction()
                    .replace(R.id.container, Camera2Fragment.newInstance())
                    .commit();
        }
    }




    public Bundle getClientData() {
        Intent intent = getIntent();
        return intent.getExtras();
    }




}
