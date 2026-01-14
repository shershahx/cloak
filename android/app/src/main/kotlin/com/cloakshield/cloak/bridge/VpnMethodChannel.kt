package com.cloakshield.cloak.bridge

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.cloakshield.cloak.vpn.CloakVpnService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter MethodChannel handler for VPN communication
 */
class VpnMethodChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    
    companion object {
        private const val TAG = "VpnMethodChannel"
        private const val CHANNEL_NAME = "com.cloakshield.cloak/vpn"
        private const val EVENT_CHANNEL_NAME = "com.cloakshield.cloak/vpn_events"
        
        const val VPN_PERMISSION_REQUEST_CODE = 1001
    }
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    
    private var pendingResult: MethodChannel.Result? = null
    private var pendingDnsServer: String = "8.8.8.8"
    private var pendingBlockAds: Boolean = true
    private var pendingBlockTrackers: Boolean = true
    private var pendingBlockAnnoyances: Boolean = true
    
    /**
     * Register the channels with Flutter engine
     */
    fun register(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )
        methodChannel?.setMethodCallHandler(this)
        
        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL_NAME
        )
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                setupVpnCallbacks()
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
        
        Log.d(TAG, "MethodChannel registered")
    }
    
    /**
     * Unregister channels
     */
    fun unregister() {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        eventSink = null
    }
    
    /**
     * Setup callbacks from VPN service to Flutter
     */
    private fun setupVpnCallbacks() {
        CloakVpnService.onStateChanged = { state ->
            mainHandler.post {
                sendEvent("onVpnStateChanged", state)
            }
        }
        
        CloakVpnService.onDnsQuery = { domain, blocked, category ->
            mainHandler.post {
                sendEvent("onDnsQuery", mapOf(
                    "domain" to domain,
                    "blocked" to blocked,
                    "category" to category,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        }
        
        CloakVpnService.onStatsUpdate = {
            mainHandler.post {
                sendEvent("onStatsUpdate", mapOf(
                    "totalBlocked" to CloakVpnService.totalBlocked,
                    "totalAllowed" to CloakVpnService.totalAllowed,
                    "adsBlocked" to CloakVpnService.adsBlocked,
                    "trackersBlocked" to CloakVpnService.trackersBlocked,
                    "annoyancesBlocked" to CloakVpnService.annoyancesBlocked
                ))
            }
        }
    }
    
    /**
     * Send event to Flutter (must be called on main thread)
     */
    private fun sendEvent(type: String, data: Any?) {
        try {
            eventSink?.success(mapOf(
                "type" to type,
                "data" to data
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error sending event: ${e.message}")
        }
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "Method called: ${call.method}")
        
        when (call.method) {
            "prepareVpn" -> {
                prepareVpn(result)
            }
            
            "startVpn" -> {
                val dnsServer = call.argument<String>("dnsServer") ?: "8.8.8.8"
                val blockAds = call.argument<Boolean>("blockAds") ?: true
                val blockTrackers = call.argument<Boolean>("blockTrackers") ?: true
                val blockAnnoyances = call.argument<Boolean>("blockAnnoyances") ?: true
                
                startVpn(dnsServer, blockAds, blockTrackers, blockAnnoyances, result)
            }
            
            "stopVpn" -> {
                stopVpn(result)
            }
            
            "isVpnRunning" -> {
                result.success(CloakVpnService.isRunning)
            }
            
            "getStats" -> {
                result.success(mapOf(
                    "totalBlocked" to CloakVpnService.totalBlocked,
                    "totalAllowed" to CloakVpnService.totalAllowed,
                    "adsBlocked" to CloakVpnService.adsBlocked,
                    "trackersBlocked" to CloakVpnService.trackersBlocked,
                    "annoyancesBlocked" to CloakVpnService.annoyancesBlocked,
                    "todayBlocked" to CloakVpnService.totalBlocked // TODO: Track daily
                ))
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * Check if VPN permission is granted
     */
    private fun prepareVpn(result: MethodChannel.Result) {
        val intent = VpnService.prepare(context)
        
        if (intent != null) {
            // Need to request permission
            pendingResult = result
            if (context is Activity) {
                context.startActivityForResult(intent, VPN_PERMISSION_REQUEST_CODE)
            } else {
                result.success(false)
            }
        } else {
            // Already have permission
            result.success(true)
        }
    }
    
    /**
     * Start the VPN service
     */
    private fun startVpn(
        dnsServer: String,
        blockAds: Boolean,
        blockTrackers: Boolean,
        blockAnnoyances: Boolean,
        result: MethodChannel.Result
    ) {
        val vpnIntent = VpnService.prepare(context)
        
        if (vpnIntent != null) {
            // Need permission first
            pendingResult = result
            pendingDnsServer = dnsServer
            pendingBlockAds = blockAds
            pendingBlockTrackers = blockTrackers
            pendingBlockAnnoyances = blockAnnoyances
            
            if (context is Activity) {
                context.startActivityForResult(vpnIntent, VPN_PERMISSION_REQUEST_CODE)
            } else {
                result.success(false)
            }
            return
        }
        
        // Start the VPN service
        val intent = Intent(context, CloakVpnService::class.java).apply {
            action = CloakVpnService.ACTION_START
            putExtra(CloakVpnService.EXTRA_DNS_SERVER, dnsServer)
            putExtra(CloakVpnService.EXTRA_BLOCK_ADS, blockAds)
            putExtra(CloakVpnService.EXTRA_BLOCK_TRACKERS, blockTrackers)
            putExtra(CloakVpnService.EXTRA_BLOCK_ANNOYANCES, blockAnnoyances)
        }
        
        context.startService(intent)
        result.success(true)
    }
    
    /**
     * Stop the VPN service
     */
    private fun stopVpn(result: MethodChannel.Result) {
        val intent = Intent(context, CloakVpnService::class.java).apply {
            action = CloakVpnService.ACTION_STOP
        }
        context.startService(intent)
        result.success(true)
    }
    
    /**
     * Handle VPN permission result from Activity
     */
    fun onActivityResult(requestCode: Int, resultCode: Int) {
        if (requestCode == VPN_PERMISSION_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                // Permission granted, start VPN
                val intent = Intent(context, CloakVpnService::class.java).apply {
                    action = CloakVpnService.ACTION_START
                    putExtra(CloakVpnService.EXTRA_DNS_SERVER, pendingDnsServer)
                    putExtra(CloakVpnService.EXTRA_BLOCK_ADS, pendingBlockAds)
                    putExtra(CloakVpnService.EXTRA_BLOCK_TRACKERS, pendingBlockTrackers)
                    putExtra(CloakVpnService.EXTRA_BLOCK_ANNOYANCES, pendingBlockAnnoyances)
                }
                context.startService(intent)
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }
}
