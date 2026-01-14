package com.cloakshield.cloak.blocking

import android.content.res.AssetManager
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Manages blocklists and whitelists loaded from assets
 * 
 * SECURITY NOTES:
 * - All lists are loaded from local assets only (no network requests)
 * - Domain matching is case-insensitive and normalized
 * - Whitelist takes priority over blocklist to prevent breaking essential services
 * - No user data is collected or transmitted
 */
class BlocklistManager(private val assets: AssetManager) {
    
    companion object {
        private const val TAG = "BlocklistManager"
        
        // Combined blocklist file (primary source)
        private const val FILE_BLOCKLIST = "blocklist.txt"
        private const val FILE_WHITELIST = "whitelist.txt"
    }
    
    // Main blocklist set for O(1) lookups
    private val _blocklist = HashSet<String>()
    val blocklist: Set<String> get() = _blocklist
    
    // Whitelist - domains that should NEVER be blocked
    private val _whitelist = HashSet<String>()
    val whitelist: Set<String> get() = _whitelist
    
    // Category-specific sets for stats (derived from patterns)
    private val adsSet = HashSet<String>()
    private val trackingSet = HashSet<String>()
    private val annoyancesSet = HashSet<String>()
    
    val size: Int get() = _blocklist.size
    val whitelistSize: Int get() = _whitelist.size
    
    // Ad-related domain patterns
    private val adPatterns = listOf(
        "ads", "ad.", "adserver", "adservice", "adsystem", "adtech",
        "banner", "doubleclick", "googlesyndication", "googleads",
        "pagead", "pubads", "advert", "adnxs", "advertising"
    )
    
    // Tracking-related domain patterns
    private val trackingPatterns = listOf(
        "track", "tracker", "analytics", "telemetry", "beacon",
        "pixel", "metrics", "collect", "stats", "log.", "logging",
        "measure", "segment", "hotjar", "mouseflow", "clickstream"
    )
    
    /**
     * Load blocklists and whitelist based on user preferences
     */
    suspend fun loadBlocklists(
        blockAds: Boolean = true,
        blockTrackers: Boolean = true,
        blockAnnoyances: Boolean = true
    ) = withContext(Dispatchers.IO) {
        _blocklist.clear()
        _whitelist.clear()
        adsSet.clear()
        trackingSet.clear()
        annoyancesSet.clear()
        
        try {
            // ALWAYS load whitelist first - these domains are essential
            loadFile(FILE_WHITELIST)?.let { domains ->
                _whitelist.addAll(domains)
                Log.d(TAG, "Loaded ${domains.size} whitelisted domains")
            } ?: Log.w(TAG, "Whitelist file not found, continuing without whitelist")
            
            // Load the combined blocklist file
            val allDomains = loadFile(FILE_BLOCKLIST)
            
            if (allDomains != null) {
                Log.d(TAG, "Loaded ${allDomains.size} total domains from blocklist")
                
                // Categorize and filter domains
                for (domain in allDomains) {
                    // Skip whitelisted domains
                    if (isWhitelisted(domain)) continue
                    
                    // Categorize by pattern matching
                    val category = categorizeDomain(domain)
                    
                    // Only add if the category is enabled
                    val shouldAdd = when (category) {
                        "ads" -> blockAds
                        "tracking" -> blockTrackers
                        "annoyances" -> blockAnnoyances
                        else -> blockAds // Default to ads category
                    }
                    
                    if (shouldAdd) {
                        _blocklist.add(domain)
                        when (category) {
                            "ads" -> adsSet.add(domain)
                            "tracking" -> trackingSet.add(domain)
                            "annoyances" -> annoyancesSet.add(domain)
                            else -> adsSet.add(domain)
                        }
                    }
                }
                
                // Remove any overly-broad domains that could break services
                removeOverlyBroadDomains()
                
                Log.d(TAG, "Final blocklist: ${_blocklist.size} domains (${adsSet.size} ads, ${trackingSet.size} tracking, ${annoyancesSet.size} annoyances)")
            } else {
                Log.e(TAG, "Failed to load blocklist file!")
            }
            
            Log.d(TAG, "Total blocklist size: ${_blocklist.size}, Whitelist size: ${_whitelist.size}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error loading blocklists", e)
        }
    }
    
    /**
     * Categorize a domain based on its name patterns
     */
    private fun categorizeDomain(domain: String): String {
        val lower = domain.lowercase()
        
        // Check ad patterns
        for (pattern in adPatterns) {
            if (lower.contains(pattern)) return "ads"
        }
        
        // Check tracking patterns
        for (pattern in trackingPatterns) {
            if (lower.contains(pattern)) return "tracking"
        }
        
        // Default to ads (most common category)
        return "ads"
    }
    
    /**
     * Remove overly-broad domains that could break essential services
     */
    private fun removeOverlyBroadDomains() {
        val dangerousDomains = setOf(
            // Top-level service domains that would break everything
            "google.com",
            "googleapis.com",
            "gstatic.com",
            "googlevideo.com",
            "youtube.com",
            "ytimg.com",
            "facebook.com",
            "fbcdn.net",
            "twitter.com",
            "twimg.com",
            "instagram.com",
            "cdninstagram.com",
            "reddit.com",
            "redditmedia.com",
            "redditstatic.com",
            "amazon.com",
            "amazonaws.com",
            "cloudfront.net",
            "microsoft.com",
            "live.com",
            "apple.com",
            "icloud.com",
            "akamaihd.net",
            "akamai.net",
            "cloudflare.com",
            "fastly.net",
            "github.com",
            "githubusercontent.com",
            "whatsapp.com",
            "whatsapp.net",
            "discord.com",
            "discordapp.com",
            "spotify.com",
            "scdn.co",
            "netflix.com",
            "nflxvideo.net"
        )
        
        var removed = 0
        dangerousDomains.forEach { domain ->
            if (_blocklist.remove(domain)) {
                adsSet.remove(domain)
                trackingSet.remove(domain)
                annoyancesSet.remove(domain)
                removed++
            }
        }
        
        if (removed > 0) {
            Log.d(TAG, "Removed $removed overly-broad domains from blocklist")
        }
    }
    
    /**
     * Load domains from a file in assets/blocklists directory
     */
    private fun loadFile(filename: String): Set<String>? {
        return try {
            assets.open("blocklists/$filename").bufferedReader().useLines { lines ->
                lines
                    .filter { it.isNotBlank() && !it.startsWith('#') && !it.startsWith('*') }
                    .map { it.trim().lowercase() }
                    .toHashSet()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading $filename", e)
            null
        }
    }
    
    /**
     * Check if a domain is whitelisted (essential service)
     */
    fun isWhitelisted(domain: String): Boolean {
        val normalized = domain.lowercase().trimEnd('.')
        
        // Exact match
        if (_whitelist.contains(normalized)) {
            return true
        }
        
        // Check if any parent domain is whitelisted
        var current = normalized
        while (current.contains('.')) {
            current = current.substringAfter('.')
            if (_whitelist.contains(current)) {
                return true
            }
        }
        
        return false
    }
    
    /**
     * Get the category of a blocked domain
     */
    fun getCategory(domain: String): String? {
        val normalized = domain.lowercase()
        
        // Check direct match first
        when {
            adsSet.contains(normalized) -> return "ads"
            trackingSet.contains(normalized) -> return "tracking"
            annoyancesSet.contains(normalized) -> return "annoyances"
        }
        
        // Check parent domains
        var current = normalized
        while (current.contains('.')) {
            current = current.substringAfter('.')
            when {
                adsSet.contains(current) -> return "ads"
                trackingSet.contains(current) -> return "tracking"
                annoyancesSet.contains(current) -> return "annoyances"
            }
        }
        
        return null
    }
    
    /**
     * Check if a domain should be blocked
     * Whitelist takes priority over blocklist
     */
    fun isBlocked(domain: String): Boolean {
        // SECURITY: Whitelist check first - essential services always allowed
        if (isWhitelisted(domain)) {
            return false
        }
        return DomainMatcher.shouldBlock(domain, _blocklist) != null
    }
    
    /**
     * Get blocking decision with reason
     */
    fun getBlockDecision(domain: String): BlockDecision {
        if (isWhitelisted(domain)) {
            return BlockDecision(false, null, "whitelisted")
        }
        
        val matchedDomain = DomainMatcher.shouldBlock(domain, _blocklist)
        return if (matchedDomain != null) {
            BlockDecision(true, getCategory(matchedDomain), matchedDomain)
        } else {
            BlockDecision(false, null, null)
        }
    }
}

/**
 * Result of a blocking decision
 */
data class BlockDecision(
    val blocked: Boolean,
    val category: String?,
    val matchedDomain: String?
)
