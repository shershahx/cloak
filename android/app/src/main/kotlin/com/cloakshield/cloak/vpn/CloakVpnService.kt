package com.cloakshield.cloak.vpn

import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import com.cloakshield.cloak.MainActivity
import com.cloakshield.cloak.blocking.BlocklistManager
import com.cloakshield.cloak.blocking.DomainMatcher
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.ByteBuffer

/**
 * Cloak VPN Service - DNS-based ad/tracker blocker
 * 
 * This service creates a local VPN that intercepts DNS queries (port 53),
 * checks them against a blocklist, and either blocks or forwards them.
 */
class CloakVpnService : VpnService() {

    companion object {
        private const val TAG = "CloakVpnService"
        
        // VPN Configuration
        private const val VPN_ADDRESS = "10.0.0.2"
        private const val VPN_ROUTE = "0.0.0.0"
        private const val VPN_DNS = "10.0.0.1"
        private const val VPN_MTU = 1500
        
        // Intent actions
        const val ACTION_START = "com.cloakshield.cloak.START_VPN"
        const val ACTION_STOP = "com.cloakshield.cloak.STOP_VPN"
        const val EXTRA_DNS_SERVER = "dns_server"
        const val EXTRA_BLOCK_ADS = "block_ads"
        const val EXTRA_BLOCK_TRACKERS = "block_trackers"
        const val EXTRA_BLOCK_ANNOYANCES = "block_annoyances"
        
        // State
        @Volatile
        var isRunning = false
            private set
        
        // Statistics
        @Volatile
        var totalBlocked = 0L
            private set
        @Volatile
        var totalAllowed = 0L
            private set
        @Volatile
        var adsBlocked = 0L
            private set
        @Volatile
        var trackersBlocked = 0L
            private set
        @Volatile
        var annoyancesBlocked = 0L
            private set
        
        // Callbacks for Flutter communication
        var onDnsQuery: ((domain: String, blocked: Boolean, category: String?) -> Unit)? = null
        var onStateChanged: ((state: String) -> Unit)? = null
        var onStatsUpdate: (() -> Unit)? = null
        
        fun resetStats() {
            totalBlocked = 0
            totalAllowed = 0
            adsBlocked = 0
            trackersBlocked = 0
            annoyancesBlocked = 0
        }
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var vpnJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    private lateinit var blocklistManager: BlocklistManager
    private var upstreamDnsServer = "8.8.8.8"
    
    // Blocklist toggles
    private var blockAds = true
    private var blockTrackers = true
    private var blockAnnoyances = true

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "CloakVpnService created")
        blocklistManager = BlocklistManager(assets)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand received")
        
        if (intent == null) {
            return START_NOT_STICKY
        }

        val action = intent.action
        
        when (action) {
            ACTION_START -> {
                upstreamDnsServer = intent.getStringExtra(EXTRA_DNS_SERVER) ?: "8.8.8.8"
                blockAds = intent.getBooleanExtra(EXTRA_BLOCK_ADS, true)
                blockTrackers = intent.getBooleanExtra(EXTRA_BLOCK_TRACKERS, true)
                blockAnnoyances = intent.getBooleanExtra(EXTRA_BLOCK_ANNOYANCES, true)
                
                startVpn()
            }
            ACTION_STOP -> {
                stopVpn()
            }
        }
        
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
        scope.cancel()
        Log.d(TAG, "CloakVpnService destroyed")
    }

    private fun startVpn() {
        if (isRunning) {
            Log.d(TAG, "VPN already running")
            return
        }

        Log.d(TAG, "Starting VPN...")
        onStateChanged?.invoke("connecting")

        try {
            // Load blocklist
            scope.launch {
                blocklistManager.loadBlocklists(blockAds, blockTrackers, blockAnnoyances)
                Log.d(TAG, "Loaded ${blocklistManager.size} domains")
            }

            // Start foreground notification
            val notification = VpnNotification.create(this)
            startForeground(VpnNotification.NOTIFICATION_ID, notification)

            // Configure VPN interface
            val builder = Builder()
                .setSession("Cloak")
                .setMtu(VPN_MTU)
                .addAddress(VPN_ADDRESS, 32)
                .addDnsServer(VPN_DNS)
                .addRoute(VPN_DNS, 32) // Only route DNS traffic through VPN
                .setBlocking(true)

            // Configure intent for notification tap
            val configureIntent = PendingIntent.getActivity(
                this,
                0,
                Intent(this, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.setConfigureIntent(configureIntent)

            // Allow apps to bypass VPN (optional - for allowlist)
            // builder.addDisallowedApplication("com.example.app")

            vpnInterface = builder.establish()

            if (vpnInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface")
                onStateChanged?.invoke("error")
                return
            }

            isRunning = true
            onStateChanged?.invoke("connected")
            Log.d(TAG, "VPN interface established")

            // Start packet handling
            startPacketLoop()

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN", e)
            onStateChanged?.invoke("error")
            stopVpn()
        }
    }

    private fun stopVpn() {
        Log.d(TAG, "Stopping VPN...")
        onStateChanged?.invoke("disconnecting")
        
        isRunning = false
        vpnJob?.cancel()
        
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing VPN interface", e)
        }
        vpnInterface = null
        
        stopForeground(STOP_FOREGROUND_REMOVE)
        onStateChanged?.invoke("disconnected")
        Log.d(TAG, "VPN stopped")
    }

    private fun startPacketLoop() {
        vpnJob = scope.launch {
            val vpnFd = vpnInterface?.fileDescriptor ?: return@launch
            val input = FileInputStream(vpnFd)
            val output = FileOutputStream(vpnFd)
            
            val buffer = ByteArray(VPN_MTU)
            
            Log.d(TAG, "Packet loop started")
            
            while (isActive && isRunning) {
                try {
                    val length = input.read(buffer)
                    if (length > 0) {
                        handlePacket(buffer, length, output)
                    }
                } catch (e: Exception) {
                    if (isRunning) {
                        Log.e(TAG, "Error reading packet", e)
                    }
                    break
                }
            }
            
            Log.d(TAG, "Packet loop ended")
        }
    }

    private suspend fun handlePacket(packet: ByteArray, length: Int, output: FileOutputStream) {
        // Parse IP header to check if it's UDP
        if (length < 28) return // Minimum IP + UDP header size
        
        val ipVersion = (packet[0].toInt() and 0xF0) shr 4
        if (ipVersion != 4) return // Only handle IPv4 for now
        
        val protocol = packet[9].toInt() and 0xFF
        if (protocol != 17) return // 17 = UDP
        
        val ipHeaderLength = (packet[0].toInt() and 0x0F) * 4
        val destPort = ((packet[ipHeaderLength + 2].toInt() and 0xFF) shl 8) or 
                       (packet[ipHeaderLength + 3].toInt() and 0xFF)
        
        // Only handle DNS (port 53)
        if (destPort != 53) return
        
        val udpDataOffset = ipHeaderLength + 8
        val dnsData = packet.copyOfRange(udpDataOffset, length)
        
        // Parse DNS query
        val domain = DnsPacketParser.extractDomain(dnsData)
        if (domain == null) {
            // Forward unknown DNS queries
            forwardDnsQuery(packet, length, output)
            return
        }
        
        // Check whitelist first, then blocklist
        val blockDecision = blocklistManager.getBlockDecision(domain)
        
        if (blockDecision.blocked) {
            // Domain is blocked
            val category = blockDecision.category
            
            // Update stats
            totalBlocked++
            when (category) {
                "ads" -> adsBlocked++
                "tracking" -> trackersBlocked++
                "annoyances" -> annoyancesBlocked++
            }
            
            Log.d(TAG, "BLOCKED: $domain ($category) matched: ${blockDecision.matchedDomain}")
            onDnsQuery?.invoke(domain, true, category)
            onStatsUpdate?.invoke()
            
            // Send blocked response (0.0.0.0)
            val response = DnsPacketParser.createBlockedResponse(packet, length, dnsData)
            if (response != null) {
                withContext(Dispatchers.IO) {
                    output.write(response)
                    output.flush()
                }
            }
        } else {
            // Domain is allowed (whitelisted or not in blocklist) - forward to real DNS
            totalAllowed++
            
            val reason = if (blockDecision.matchedDomain == "whitelisted") " (whitelisted)" else ""
            Log.d(TAG, "ALLOWED: $domain$reason")
            onDnsQuery?.invoke(domain, false, null)
            
            forwardDnsQuery(packet, length, output)
        }
    }

    private suspend fun forwardDnsQuery(originalPacket: ByteArray, length: Int, output: FileOutputStream) {
        withContext(Dispatchers.IO) {
            try {
                val ipHeaderLength = (originalPacket[0].toInt() and 0x0F) * 4
                val udpDataOffset = ipHeaderLength + 8
                val dnsQuery = originalPacket.copyOfRange(udpDataOffset, length)
                
                // Send to upstream DNS
                val socket = DatagramSocket()
                socket.soTimeout = 5000
                
                val dnsAddress = InetAddress.getByName(upstreamDnsServer)
                val requestPacket = DatagramPacket(dnsQuery, dnsQuery.size, dnsAddress, 53)
                socket.send(requestPacket)
                
                // Receive response
                val responseBuffer = ByteArray(512)
                val responsePacket = DatagramPacket(responseBuffer, responseBuffer.size)
                socket.receive(responsePacket)
                socket.close()
                
                // Build response packet
                val response = DnsPacketParser.buildResponsePacket(
                    originalPacket,
                    length,
                    responseBuffer.copyOfRange(0, responsePacket.length)
                )
                
                if (response != null) {
                    output.write(response)
                    output.flush()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error forwarding DNS query", e)
            }
        }
    }
}
