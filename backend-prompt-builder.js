/**
 * FyreWay Backend Helper (Node.js / Edge / Serverless)
 * Converts a simple non-technical customer order from the website
 * into a complete technical config + Claude Build Prompt.
 */

export function enrichOrderAndBuildClaudePrompt(userOrder) {
  const slug =
    (userOrder.app?.name || "vpnapp")
      .toLowerCase()
      .replace(/[^a-z0-9]/g, "") || "vpnapp";

  const platforms = userOrder.app?.platforms || ["android", "ios"];
  const hasSubs =
    userOrder.monetization?.model === "subscriptions_and_ads" ||
    userOrder.monetization?.model === "subscriptions_only";
  const hasAds =
    userOrder.monetization?.model === "subscriptions_and_ads" ||
    userOrder.monetization?.model === "ads_only";

  // 1. Auto-fill all technical & store configuration on the backend
  const technicalConfig = {
    schemaVersion: "1.0",
    backend: {
      provider: "fyreway",
      baseUrl: "https://fyreway.com",
      tenantId: `fw_${slug}_${Date.now().toString(36)}`,
    },
    developer: {
      name: userOrder.customer?.name,
      email: userOrder.customer?.email,
      supportEmail: userOrder.customer?.email,
      privacyPolicyUrl: `https://fyreway.com/legal/${slug}/privacy`,
      termsUrl: `https://fyreway.com/legal/${slug}/terms`,
    },
    app: {
      name: userOrder.app?.name,
      version: "1.0.0",
      platforms,
      androidPackageName: platforms.includes("android") ? `com.fyreway.${slug}` : null,
      iosBundleId: platforms.includes("ios") ? `com.fyreway.${slug}` : null,
      authMode: "anonymous_device",
    },
    vpn: {
      protocols: ["wireguard", "openvpn"],
      servers: userOrder.servers,
      features: userOrder.vpnFeatures || ["smart_location", "kill_switch", "auto_connect"],
    },
    modules: userOrder.modules || [],
    monetization: {
      iapProvider: hasSubs ? "revenuecat" : "none",
      freeTrialDays: userOrder.monetization?.freeTrialDays ?? 3,
      productIds: hasSubs
        ? {
            weekly: (userOrder.monetization?.plans || []).includes("weekly") ? `${slug}_weekly` : null,
            monthly: (userOrder.monetization?.plans || []).includes("monthly") ? `${slug}_monthly` : null,
            yearly: (userOrder.monetization?.plans || []).includes("yearly") ? `${slug}_yearly` : null,
          }
        : null,
      adsNetwork: hasAds ? "admob" : "none",
    },
    integrations: ["firebase_analytics", "fcm_push", "crashlytics"],
    branding: userOrder.branding,
  };

  // 2. Generate the ready-to-run Claude Build Prompt
  const claudePrompt = `You are customizing the FyreWay Flutter White-Label VPN template repository.
Apply the following specification cleanly without breaking existing FyreWay SDK integration:

1. APP IDENTITY & STORE CONFIG:
- App Name: ${technicalConfig.app.name}
- Platforms: ${technicalConfig.app.platforms.join(", ")}
- Android Package: ${technicalConfig.app.androidPackageName || "N/A"}
- iOS Bundle ID: ${technicalConfig.app.iosBundleId || "N/A"}
- Tenant ID: ${technicalConfig.backend.tenantId}

2. SERVERS & PROTOCOLS:
- Protocols: ${technicalConfig.vpn.protocols.join(", ")}
- Servers: Free=${technicalConfig.vpn.servers.freeCount}, Premium=${technicalConfig.vpn.servers.premiumCount}, Gaming=${technicalConfig.vpn.servers.gamingCount}, Streaming=${technicalConfig.vpn.servers.streamingCount}
- Features: ${technicalConfig.vpn.features.join(", ")}

3. MODULES & MONETIZATION:
- Modules: ${technicalConfig.modules.join(", ")}
- IAP Provider: ${technicalConfig.monetization.iapProvider} (Trial: ${technicalConfig.monetization.freeTrialDays} days)
- Product IDs: ${JSON.stringify(technicalConfig.monetization.productIds)}
- Ads: ${technicalConfig.monetization.adsNetwork}

4. BRANDING:
- Theme: ${technicalConfig.branding.themePreset} (${technicalConfig.branding.themeMode}), Layout: ${technicalConfig.branding.homeLayout}
- Colors: Primary=${technicalConfig.branding.colors.primary}, Accent=${technicalConfig.branding.colors.accent}, Background=${technicalConfig.branding.colors.background}
- Notes: ${technicalConfig.branding.customNotes || "None"}

TASKS:
1. Update lib/config/whitelabel_config.dart with this exact JSON config.
2. Update Android applicationId/App Name and iOS PRODUCT_BUNDLE_IDENTIFIER/CFBundleDisplayName.
3. Apply app icon & splash logo assets if URLs are provided and run flutter_launcher_icons.
4. Run flutter analyze and trigger release testing build (APK / IPA).

Full Config JSON:
${JSON.stringify(technicalConfig, null, 2)}`;

  return { technicalConfig, claudePrompt };
}
