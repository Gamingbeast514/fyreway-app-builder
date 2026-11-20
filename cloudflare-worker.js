/**
 * FyreWay Cloud Build Proxy (Cloudflare Worker - Free Tier)
 * Keeps your GITHUB_TOKEN secret while letting your GitHub Pages form
 * trigger GitHub Actions builds and return the direct APK Release link.
 *
 * Env vars to set in Cloudflare Worker:
 * - GITHUB_TOKEN: Fine-grained PAT with Actions (Read/Write) + Contents (Read) on Gamingbeast514/kovra-vpn
 * - GITHUB_OWNER: Gamingbeast514
 * - GITHUB_REPO: kovra-vpn
 * - GITHUB_BRANCH: whitelabel-template
 */

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

function hexToDart(hex, fallback) {
  return /^#[0-9A-Fa-f]{6}$/.test(hex || "")
    ? `0xFF${hex.slice(1).toUpperCase()}`
    : fallback;
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    const owner = env.GITHUB_OWNER || "Gamingbeast514";
    const repo = env.GITHUB_REPO || "kovra-vpn";
    const ref = env.GITHUB_BRANCH || "whitelabel-template";
    const ghHeaders = {
      Authorization: `Bearer ${env.GITHUB_TOKEN}`,
      Accept: "application/vnd.github+json",
      "User-Agent": "FyreWay-App-Builder",
    };

    // 1. Trigger GitHub Actions workflow_dispatch
    if (request.method === "POST" && url.pathname === "/api/whitelabel/orders") {
      const order = await request.json();
      const appName = (order.app?.name || "FyreVPN").trim();
      const slug = appName.toLowerCase().replace(/[^a-z0-9]/g, "") || "vpnapp";
      const appId = `com.fyreway.${slug}`;
      const model = order.monetization?.model || "subscriptions_and_ads";

      const inputs = {
        app_name: appName,
        app_id: appId,
        primary_color: hexToDart(order.branding?.colors?.primary, "0xFF3B82F6"),
        accent_color: hexToDart(order.branding?.colors?.accent, "0xFF10B981"),
        bg_color: hexToDart(order.branding?.colors?.background, "0xFF0B0F19"),
        free_servers: String(order.servers?.freeCount ?? 5),
        prem_servers: String(order.servers?.premiumCount ?? 20),
        gaming_servers: String(order.servers?.gamingCount ?? 4),
        streaming_servers: String(order.servers?.streamingCount ?? 6),
        ads_enabled: String(model.includes("ads")),
        paywall_enabled: String(model.includes("subscriptions")),
        plans: (order.monetization?.plans || ["weekly", "monthly", "yearly"]).join(","),
        mod_location: String((order.modules || []).includes("location_checker")),
        mod_speed: String((order.modules || []).includes("speed_test")),
        mod_invite: String((order.modules || []).includes("invite_friends")),
        icon_url: order.branding?.appIconUrl || "",
      };

      const dispatchRes = await fetch(
        `https://api.github.com/repos/${owner}/${repo}/actions/workflows/whitelabel-build.yml/dispatches`,
        {
          method: "POST",
          headers: { ...ghHeaders, "Content-Type": "application/json" },
          body: JSON.stringify({ ref, inputs }),
        }
      );

      if (!dispatchRes.ok) {
        return json({ error: `GitHub dispatch failed (${dispatchRes.status})` }, 502);
      }

      // Fetch latest run ID so the UI can poll its progress
      await new Promise((r) => setTimeout(r, 1500));
      const runsRes = await fetch(
        `https://api.github.com/repos/${owner}/${repo}/actions/workflows/whitelabel-build.yml/runs?per_page=1`,
        { headers: ghHeaders }
      );
      const runsData = await runsRes.json();
      const runId = runsData.workflow_runs?.[0]?.id;

      return json({ jobId: `${runId}:${appId}`, status: "queued" }, 202);
    }

    // 2. Poll build status & return GitHub Release APK download link
    if (request.method === "GET" && url.pathname === "/api/whitelabel/status") {
      const idParam = url.searchParams.get("id") || "";
      const [runId, appId] = idParam.split(":");
      if (!runId) return json({ error: "Invalid job id" }, 400);

      const runRes = await fetch(
        `https://api.github.com/repos/${owner}/${repo}/actions/runs/${runId}`,
        { headers: ghHeaders }
      );
      const run = await runRes.json();

      if (run.status === "completed") {
        if (run.conclusion === "success") {
          const downloadUrl = `https://github.com/${owner}/${repo}/releases/download/build-${runId}/${appId}-release.apk`;
          return json({
            jobId: idParam,
            status: "ready",
            message: "APK is ready for testing!",
            downloadUrl,
          });
        }
        return json({ jobId: idParam, status: "error", message: `Build failed (${run.conclusion})` });
      }

      return json({
        jobId: idParam,
        status: run.status || "in_progress",
        message: "Building release APK in GitHub Cloud...",
      });
    }

    return json({ error: "Not found" }, 404);
  },
};
