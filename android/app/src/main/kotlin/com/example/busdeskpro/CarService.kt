package com.example.busdeskpro

import android.app.Service
import android.content.Intent
import android.os.IBinder

class CarService : Service() {
    override fun onBind(intent: Intent): IBinder? {
        return null
    }
    
    override fun onCreate() {
        super.onCreate()
        // Android Auto Service wird erstellt
    }
}
