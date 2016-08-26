package com.example.abrahamsofer.ident;

import android.app.Activity;
import android.content.Context;
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
        final Bundle b = this.getIntent().getExtras();
        String name = b.getString("name");
        final String answer = b.getString("email");
        question.setText("please enter your email " +
                "address to confirm your Identitiy ");

        final EditText editText = (EditText) findViewById(R.id.answerText);
        editText.setHint("Enter email");
        final Bundle userData = new Bundle();
        ImageButton button = (ImageButton) findViewById(R.id.confirm);
        button.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View arg0) {
                String email = editText.getText().toString();
                Context context = arg0.getContext();
                if (email.length() == 0) {
                    Toast.makeText(getBaseContext(),"Please enter your email address",Toast.LENGTH_SHORT).show();
                }else if(email.compareTo(answer) == 0) {
                     // Launch Success Activity
                    Intent in  = new Intent(context,SuccessActivity.class);
                    in.putExtras(b);
                    context.startActivity(in);
                    ((Activity)context).finish();
                }else{
                    //Lauch FailActivity
                    userData.putString("error","Incorrect data");
                    Intent in  = new Intent(context,FailActivity.class);
                    in.putExtras(userData);
                    context.startActivity(in);
                    ((Activity)context).finish();
                }



			}
		});


       /* if (null == savedInstanceState) {
            getFragmentManager().beginTransaction()
                    .replace(R.id.container, Camera2Fragment.newInstance())
                    .commit();
        } */
    }



    /*
    public Bundle getClientData() {
        Intent intent = getIntent();
        return intent.getExtras();
    }*/




}
