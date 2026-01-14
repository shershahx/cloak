package com.cloakshield.cloak

import android.content.Intent
import android.os.Bundle
import com.cloakshield.cloak.bridge.VpnMethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    
    private var vpnMethodChannel: VpnMethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register VPN method channel
        vpnMethodChannel = VpnMethodChannel(this)
        vpnMethodChannel?.register(flutterEngine)
    }
    
    override fun onDestroy() {
        vpnMethodChannel?.unregister()
        vpnMethodChannel = null
        super.onDestroy()
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        // Handle VPN permission result
        if (requestCode == VpnMethodChannel.VPN_PERMISSION_REQUEST_CODE) {
            vpnMethodChannel?.onActivityResult(requestCode, resultCode)
        }
    }
}
