# Cloak Security Policy

## Overview

Cloak is designed with privacy and security as core principles. This document outlines the security measures implemented in the application.

## Data Collection Policy

### What We DO NOT Collect
- ❌ **No personal data** - We never collect names, emails, or identifiers
- ❌ **No browsing history** - DNS queries are processed locally and never transmitted
- ❌ **No analytics/telemetry** - No tracking SDKs, no crash reporting services
- ❌ **No network transmission** - All blocking decisions happen 100% on-device
- ❌ **No logs stored** - DNS query logs are kept in memory only and cleared on app close
- ❌ **No third-party services** - No Firebase, no Google Analytics, no ad SDKs

### What We DO Store (Locally Only)
- ✅ User preferences (theme, DNS server choice, blocking categories)
- ✅ Aggregate statistics (total blocked count) - never transmitted
- ✅ Temporary DNS query log (in-memory, for debugging)

## VPN Security

### How the VPN Works
1. **Local DNS Interception**: The VPN only routes DNS traffic (port 53) through the local tunnel
2. **No Remote Servers**: Unlike commercial VPNs, Cloak does NOT route traffic through remote servers
3. **On-Device Processing**: All DNS queries are processed locally on your device
4. **Minimal Data Exposure**: Only DNS queries are intercepted; web traffic goes directly to its destination

### VPN Permissions
The app requires VPN permission solely to:
- Create a local TUN interface for DNS interception
- Filter DNS queries against the blocklist
- Return blocked responses for ad/tracker domains

## DNS Security

### DNS Server Options
- **Cloudflare (1.1.1.1)**: Privacy-focused, APNIC partnership
- **Google (8.8.8.8)**: High reliability
- **Quad9 (9.9.9.9)**: Security-focused with threat blocking
- **AdGuard (94.140.14.14)**: Additional ad-blocking at DNS level

### Future Enhancements (Planned)
- [ ] DNS-over-HTTPS (DoH) support
- [ ] DNS-over-TLS (DoT) support
- [ ] Custom DNS server configuration
- [ ] DNSSEC validation

## Blocklist Security

### Source
Blocklists are derived from community-maintained open-source filter lists including:
- EasyList (ads)
- EasyPrivacy (tracking)
- Fanboy's Annoyances

### Updates
- Blocklists are bundled with the app
- No automatic network updates (prevents MITM attacks)
- Updates only through app store releases (signed and verified)

### Whitelist Protection
Essential services are whitelisted to prevent breaking core functionality:
- Google/YouTube core services (video playback, authentication)
- Payment processors (PayPal, Stripe)
- CDNs (Cloudflare, Akamai)
- Captive portal detection

## Code Security

### Open Source
- Full source code is available for audit
- No obfuscation of security-critical code
- Community review welcome

### Permissions
Minimal permissions requested:
- `INTERNET`: Required for DNS forwarding
- `FOREGROUND_SERVICE`: Required for persistent VPN
- `BIND_VPN_SERVICE`: Required for VPN functionality

### Build Security
- Debug builds include logging
- Release builds strip debug info
- ProGuard/R8 obfuscation for release

## Reporting Security Issues

If you discover a security vulnerability:
1. Do NOT open a public issue
2. Contact the maintainers privately
3. Allow reasonable time for a fix before disclosure

## Comparison with Commercial VPNs

| Feature | Cloak | Commercial VPNs |
|---------|-------|-----------------|
| Routes all traffic | No (DNS only) | Yes |
| Remote servers | No | Yes |
| Can see your traffic | No | Yes (trust required) |
| Subscription required | No | Usually |
| Data collection | None | Varies |
| Open source | Yes | Rarely |

## Summary

Cloak is designed to be a **transparent, privacy-respecting** ad blocker that:
- Processes everything locally
- Never phones home
- Requires no account or subscription
- Is fully open source for audit
