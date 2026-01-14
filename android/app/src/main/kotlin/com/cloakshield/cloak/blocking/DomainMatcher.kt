package com.cloakshield.cloak.blocking

/**
 * Domain matching logic with subdomain support
 * 
 * If the blocklist contains "doubleclick.net":
 * - "doubleclick.net" → BLOCKED
 * - "ads.doubleclick.net" → BLOCKED  
 * - "sub.ads.doubleclick.net" → BLOCKED
 * - "notdoubleclick.net" → ALLOWED
 */
object DomainMatcher {
    
    /**
     * Check if a domain should be blocked
     * 
     * @param domain The domain to check (e.g., "ads.example.com")
     * @param blocklist The set of blocked domains
     * @return The matched domain if blocked, null if allowed
     */
    fun shouldBlock(domain: String, blocklist: Set<String>): String? {
        val normalized = domain.lowercase().trimEnd('.')
        
        // Exact match
        if (blocklist.contains(normalized)) {
            return normalized
        }
        
        // Check parent domains (subdomain matching)
        var current = normalized
        while (current.contains('.')) {
            current = current.substringAfter('.')
            if (blocklist.contains(current)) {
                return current
            }
        }
        
        return null
    }
    
    /**
     * Check if domain matches any pattern with wildcards
     * (Future enhancement for more complex matching)
     */
    fun matchesPattern(domain: String, pattern: String): Boolean {
        if (pattern.startsWith("*.")) {
            val suffix = pattern.substring(2)
            return domain == suffix || domain.endsWith(".$suffix")
        }
        return domain == pattern
    }
}
