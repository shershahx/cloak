package com.cloakshield.cloak.vpn

import android.util.Log
import java.nio.ByteBuffer

/**
 * DNS Packet Parser
 * 
 * Parses DNS queries to extract domain names and builds DNS responses.
 * 
 * DNS Packet Structure:
 * - Header (12 bytes)
 * - Questions
 * - Answers
 * - Authority
 * - Additional
 */
object DnsPacketParser {
    
    private const val TAG = "DnsPacketParser"
    
    // DNS Header offsets
    private const val DNS_HEADER_SIZE = 12
    private const val DNS_ID_OFFSET = 0
    private const val DNS_FLAGS_OFFSET = 2
    private const val DNS_QDCOUNT_OFFSET = 4
    
    /**
     * Extract domain name from a DNS query packet
     */
    fun extractDomain(dnsData: ByteArray): String? {
        if (dnsData.size < DNS_HEADER_SIZE + 5) {
            return null
        }
        
        try {
            // Check if this is a query (QR bit = 0)
            val flags = ((dnsData[DNS_FLAGS_OFFSET].toInt() and 0xFF) shl 8) or 
                        (dnsData[DNS_FLAGS_OFFSET + 1].toInt() and 0xFF)
            val isQuery = (flags and 0x8000) == 0
            
            if (!isQuery) {
                return null
            }
            
            // Parse question section
            var offset = DNS_HEADER_SIZE
            val domainParts = mutableListOf<String>()
            
            while (offset < dnsData.size) {
                val labelLength = dnsData[offset].toInt() and 0xFF
                
                if (labelLength == 0) {
                    break // End of domain name
                }
                
                if (labelLength > 63) {
                    // Pointer or invalid - not supported in queries
                    break
                }
                
                offset++
                
                if (offset + labelLength > dnsData.size) {
                    return null
                }
                
                val label = String(dnsData, offset, labelLength, Charsets.US_ASCII)
                domainParts.add(label)
                offset += labelLength
            }
            
            if (domainParts.isEmpty()) {
                return null
            }
            
            return domainParts.joinToString(".").lowercase()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing DNS query", e)
            return null
        }
    }
    
    /**
     * Create a DNS response that blocks the domain (returns 0.0.0.0)
     */
    fun createBlockedResponse(originalIpPacket: ByteArray, length: Int, dnsQuery: ByteArray): ByteArray? {
        try {
            val ipHeaderLength = (originalIpPacket[0].toInt() and 0x0F) * 4
            
            // Build DNS response
            val dnsResponse = buildBlockedDnsResponse(dnsQuery) ?: return null
            
            // Build UDP packet
            val udpLength = 8 + dnsResponse.size
            
            // Build IP packet
            val totalLength = ipHeaderLength + udpLength
            val response = ByteArray(totalLength)
            
            // Copy and modify IP header
            System.arraycopy(originalIpPacket, 0, response, 0, ipHeaderLength)
            
            // Swap source and destination IP
            for (i in 0 until 4) {
                val temp = response[12 + i]
                response[12 + i] = response[16 + i]
                response[16 + i] = temp
            }
            
            // Update total length
            response[2] = ((totalLength shr 8) and 0xFF).toByte()
            response[3] = (totalLength and 0xFF).toByte()
            
            // Reset checksum (will be calculated by the system or set to 0 for UDP)
            response[10] = 0
            response[11] = 0
            
            // Calculate IP header checksum
            val checksum = calculateChecksum(response, 0, ipHeaderLength)
            response[10] = ((checksum shr 8) and 0xFF).toByte()
            response[11] = (checksum and 0xFF).toByte()
            
            // UDP header
            val udpOffset = ipHeaderLength
            
            // Swap source and destination ports
            response[udpOffset] = originalIpPacket[udpOffset + 2]
            response[udpOffset + 1] = originalIpPacket[udpOffset + 3]
            response[udpOffset + 2] = originalIpPacket[udpOffset]
            response[udpOffset + 3] = originalIpPacket[udpOffset + 1]
            
            // UDP length
            response[udpOffset + 4] = ((udpLength shr 8) and 0xFF).toByte()
            response[udpOffset + 5] = (udpLength and 0xFF).toByte()
            
            // UDP checksum (0 = disabled)
            response[udpOffset + 6] = 0
            response[udpOffset + 7] = 0
            
            // Copy DNS response
            System.arraycopy(dnsResponse, 0, response, udpOffset + 8, dnsResponse.size)
            
            return response
            
        } catch (e: Exception) {
            Log.e(TAG, "Error creating blocked response", e)
            return null
        }
    }
    
    /**
     * Build a blocked DNS response (A record pointing to 0.0.0.0)
     */
    private fun buildBlockedDnsResponse(dnsQuery: ByteArray): ByteArray? {
        try {
            // Find the end of the question section
            var offset = DNS_HEADER_SIZE
            while (offset < dnsQuery.size && dnsQuery[offset].toInt() != 0) {
                val labelLength = dnsQuery[offset].toInt() and 0xFF
                offset += labelLength + 1
            }
            offset += 5 // Skip null byte + QTYPE (2) + QCLASS (2)
            
            val questionSize = offset - DNS_HEADER_SIZE
            
            // Response = Header + Question + Answer
            val responseSize = DNS_HEADER_SIZE + questionSize + 16 // 16 bytes for A record answer
            val response = ByteArray(responseSize)
            
            // Copy transaction ID
            response[0] = dnsQuery[0]
            response[1] = dnsQuery[1]
            
            // Flags: Response, No error
            response[2] = 0x81.toByte() // QR=1, Opcode=0, AA=0, TC=0, RD=1
            response[3] = 0x80.toByte() // RA=1, Z=0, RCODE=0
            
            // Question count: 1
            response[4] = 0
            response[5] = 1
            
            // Answer count: 1
            response[6] = 0
            response[7] = 1
            
            // Authority and Additional: 0
            response[8] = 0
            response[9] = 0
            response[10] = 0
            response[11] = 0
            
            // Copy question section
            System.arraycopy(dnsQuery, DNS_HEADER_SIZE, response, DNS_HEADER_SIZE, questionSize)
            
            // Build answer section
            val answerOffset = DNS_HEADER_SIZE + questionSize
            
            // Name pointer to question
            response[answerOffset] = 0xC0.toByte()
            response[answerOffset + 1] = 0x0C.toByte()
            
            // Type: A (1)
            response[answerOffset + 2] = 0
            response[answerOffset + 3] = 1
            
            // Class: IN (1)
            response[answerOffset + 4] = 0
            response[answerOffset + 5] = 1
            
            // TTL: 300 seconds
            response[answerOffset + 6] = 0
            response[answerOffset + 7] = 0
            response[answerOffset + 8] = 0x01.toByte()
            response[answerOffset + 9] = 0x2C.toByte()
            
            // Data length: 4 (IPv4 address)
            response[answerOffset + 10] = 0
            response[answerOffset + 11] = 4
            
            // Address: 0.0.0.0
            response[answerOffset + 12] = 0
            response[answerOffset + 13] = 0
            response[answerOffset + 14] = 0
            response[answerOffset + 15] = 0
            
            return response
            
        } catch (e: Exception) {
            Log.e(TAG, "Error building blocked DNS response", e)
            return null
        }
    }
    
    /**
     * Build a complete IP/UDP packet with DNS response
     */
    fun buildResponsePacket(originalIpPacket: ByteArray, originalLength: Int, dnsResponse: ByteArray): ByteArray? {
        try {
            val ipHeaderLength = (originalIpPacket[0].toInt() and 0x0F) * 4
            val udpLength = 8 + dnsResponse.size
            val totalLength = ipHeaderLength + udpLength
            
            val response = ByteArray(totalLength)
            
            // Copy and modify IP header
            System.arraycopy(originalIpPacket, 0, response, 0, ipHeaderLength)
            
            // Swap source and destination IP
            for (i in 0 until 4) {
                val temp = response[12 + i]
                response[12 + i] = response[16 + i]
                response[16 + i] = temp
            }
            
            // Update total length
            response[2] = ((totalLength shr 8) and 0xFF).toByte()
            response[3] = (totalLength and 0xFF).toByte()
            
            // Reset and recalculate IP checksum
            response[10] = 0
            response[11] = 0
            val checksum = calculateChecksum(response, 0, ipHeaderLength)
            response[10] = ((checksum shr 8) and 0xFF).toByte()
            response[11] = (checksum and 0xFF).toByte()
            
            // UDP header
            val udpOffset = ipHeaderLength
            
            // Swap ports
            response[udpOffset] = originalIpPacket[udpOffset + 2]
            response[udpOffset + 1] = originalIpPacket[udpOffset + 3]
            response[udpOffset + 2] = originalIpPacket[udpOffset]
            response[udpOffset + 3] = originalIpPacket[udpOffset + 1]
            
            // UDP length
            response[udpOffset + 4] = ((udpLength shr 8) and 0xFF).toByte()
            response[udpOffset + 5] = (udpLength and 0xFF).toByte()
            
            // UDP checksum (0 = disabled for IPv4)
            response[udpOffset + 6] = 0
            response[udpOffset + 7] = 0
            
            // Copy DNS response
            System.arraycopy(dnsResponse, 0, response, udpOffset + 8, dnsResponse.size)
            
            return response
            
        } catch (e: Exception) {
            Log.e(TAG, "Error building response packet", e)
            return null
        }
    }
    
    /**
     * Calculate IP header checksum
     */
    private fun calculateChecksum(data: ByteArray, offset: Int, length: Int): Int {
        var sum = 0
        var i = offset
        
        while (i < offset + length - 1) {
            sum += ((data[i].toInt() and 0xFF) shl 8) or (data[i + 1].toInt() and 0xFF)
            i += 2
        }
        
        if (length % 2 == 1) {
            sum += (data[offset + length - 1].toInt() and 0xFF) shl 8
        }
        
        while (sum shr 16 != 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        
        return sum.inv() and 0xFFFF
    }
}
