// Live Cloudflare Worker URL for remote cloud APK builds
const FYREWAY_BUILD_API_BASE = "https://fyreway-builder.handsongames786110.workers.dev";

const THEME_PRESETS = {
  cyber_dark: { primary: "#3B82F6", accent: "#10B981", bg: "#0B0F19" },
  neon_gaming: { primary: "#8B5CF6", accent: "#EC4899", bg: "#0D0B14" },
  minimal_light: { primary: "#2563EB", accent: "#0F172A", bg: "#F8FAFC" },
  emerald_shield: { primary: "#10B981", accent: "#34D399", bg: "#071312" },
};

const form = document.getElementById("whitelabelForm");
const steps = Array.from(document.querySelectorAll(".form-step"));
const stepPills = Array.from(document.querySelectorAll(".step-pill"));
const prevBtn = document.getElementById("prevBtn");
const nextBtn = document.getElementById("nextBtn");
const stepIndicator = document.getElementById("stepIndicator");

let currentStep = 1;

function goToStep(stepNumber) {
  currentStep = Math.max(1, Math.min(steps.length, stepNumber));

  steps.forEach((step) => {
    step.classList.toggle("active", Number(step.dataset.step) === currentStep);
  });

  stepPills.forEach((pill) => {
    const s = Number(pill.dataset.step);
    pill.classList.toggle("active", s === currentStep);
    pill.classList.toggle("done", s < currentStep);
  });

  prevBtn.disabled = currentStep === 1;
  nextBtn.style.display = currentStep === steps.length ? "none" : "inline-flex";
  stepIndicator.textContent = `Step ${currentStep} of ${steps.length}`;

  if (currentStep === 5) {
    renderReview();
  }
}

function validateStep(stepNumber) {
  const stepEl = steps.find((s) => Number(s.dataset.step) === stepNumber);
  const requiredFields = Array.from(stepEl.querySelectorAll("[required]")).filter(
    (el) => el.offsetParent !== null
  );

  let valid = true;
  requiredFields.forEach((field) => {
    const isOk = field.checkValidity() && field.value.trim() !== "";
    field.classList.toggle("invalid", !isOk);
    if (!isOk) valid = false;
  });

  return valid;
}

prevBtn.addEventListener("click", () => goToStep(currentStep - 1));
nextBtn.addEventListener("click", () => {
  if (validateStep(currentStep)) {
    goToStep(currentStep + 1);
  }
});

stepPills.forEach((pill) => {
  pill.addEventListener("click", () => {
    const target = Number(pill.dataset.step);
    if (target < currentStep || validateStep(currentStep)) {
      goToStep(target);
    }
  });
});

// Server category toggles
function bindToggle(checkboxId, wrapId) {
  const cb = document.getElementById(checkboxId);
  const wrap = document.getElementById(wrapId);
  const sync = () => {
    wrap.style.opacity = cb.checked ? "1" : "0.4";
    wrap.querySelector("input").disabled = !cb.checked;
  };
  cb.addEventListener("change", sync);
  sync();
}
bindToggle("enableGaming", "gamingCountWrap");
bindToggle("enableStreaming", "streamingCountWrap");

// Monetization model toggle
const monetizationModel = document.getElementById("monetizationModel");
const plansWrap = document.getElementById("plansWrap");
const trialWrap = document.getElementById("trialWrap");
function syncMonetizationUI() {
  const hasSubs =
    monetizationModel.value === "subscriptions_and_ads" ||
    monetizationModel.value === "subscriptions_only";
  plansWrap.style.display = hasSubs ? "block" : "none";
  trialWrap.style.display = hasSubs ? "block" : "none";
}
monetizationModel.addEventListener("change", syncMonetizationUI);
syncMonetizationUI();

// Sync color pickers and hex text inputs
function bindColor(pickerId, textId) {
  const picker = document.getElementById(pickerId);
  const text = document.getElementById(textId);
  picker.addEventListener("input", () => (text.value = picker.value.toUpperCase()));
  text.addEventListener("input", () => {
    if (/^#[0-9A-Fa-f]{6}$/.test(text.value)) picker.value = text.value;
  });
}
bindColor("primaryColorPicker", "primaryColor");
bindColor("accentColorPicker", "accentColor");
bindColor("bgColorPicker", "bgColor");

document.querySelectorAll('input[name="themePreset"]').forEach((radio) => {
  radio.addEventListener("change", () => {
    const preset = THEME_PRESETS[radio.value];
    if (!preset) return;
    document.getElementById("primaryColor").value = preset.primary;
    document.getElementById("primaryColorPicker").value = preset.primary;
    document.getElementById("accentColor").value = preset.accent;
    document.getElementById("accentColorPicker").value = preset.accent;
    document.getElementById("bgColor").value = preset.bg;
    document.getElementById("bgColorPicker").value = preset.bg;
  });
});

function getCheckedValues(name) {
  return Array.from(document.querySelectorAll(`input[name="${name}"]:checked`)).map(
    (el) => el.value
  );
}

let uploadedIconBase64 = null;
document.getElementById("appIconFile")?.addEventListener("change", (e) => {
  const file = e.target.files?.[0];
  const status = document.getElementById("appIconStatus");
  if (!file) {
    uploadedIconBase64 = null;
    if (status) status.textContent = "Optional — if blank, a branded shield icon is auto-generated";
    return;
  }
  const reader = new FileReader();
  reader.onload = () => {
    const res = String(reader.result || "");
    uploadedIconBase64 = res.includes(",") ? res.split(",")[1] : res;
    if (status) status.textContent = `Loaded: ${file.name} (${Math.round(file.size / 1024)} KB)`;
  };
  reader.readAsDataURL(file);
});

function buildUserOrderPayload() {
  const data = new FormData(form);
  const platform = data.get("platform");
  const enableGaming = document.getElementById("enableGaming").checked;
  const enableStreaming = document.getElementById("enableStreaming").checked;
  const monModel = data.get("monetizationModel");
  const hasSubs =
    monModel === "subscriptions_and_ads" || monModel === "subscriptions_only";

  return {
    customer: {
      name: data.get("devName"),
      email: data.get("devEmail"),
    },
    app: {
      name: (data.get("appName") || "").trim(),
      platforms: platform === "both" ? ["android", "ios"] : [platform],
    },
    servers: {
      freeCount: Number(data.get("freeServersCount") || 0),
      premiumCount: Number(data.get("premiumServersCount") || 0),
      gamingCount: enableGaming ? Number(data.get("gamingServersCount") || 0) : 0,
      streamingCount: enableStreaming ? Number(data.get("streamingServersCount") || 0) : 0,
      preferredRegions: (data.get("preferredRegions") || "")
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean),
    },
    modules: getCheckedValues("modules"),
    monetization: {
      model: monModel,
      plans: hasSubs ? getCheckedValues("plans") : [],
      freeTrialDays: hasSubs ? Number(data.get("freeTrialDays") || 0) : 0,
    },
    branding: {
      themePreset: data.get("themePreset"),
      colors: {
        primary: data.get("primaryColor"),
        accent: data.get("accentColor"),
        background: data.get("bgColor"),
      },
      appIconBase64: uploadedIconBase64,
      appIconUrl: data.get("appIconUrl") || null,
      customNotes: data.get("customNotes") || null,
    },
    submittedAt: new Date().toISOString(),
  };
}

function renderReview() {
  const order = buildUserOrderPayload();
  const summaryGrid = document.getElementById("summaryGrid");
  const monLabels = {
    subscriptions_and_ads: "VIP Subscriptions + Ads",
    subscriptions_only: "VIP Subscriptions Only",
    ads_only: "Free with Ads",
    free_no_ads: "100% Free",
  };

  summaryGrid.innerHTML = `
    <div class="summary-card"><span>App Name</span><strong>${order.app.name || "Your VPN App"}</strong></div>
    <div class="summary-card"><span>Platforms</span><strong>${order.app.platforms.map((p) => p.toUpperCase()).join(" + ")}</strong></div>
    <div class="summary-card"><span>Servers</span><strong>Free: ${order.servers.freeCount} · VIP: ${order.servers.premiumCount} · Game: ${order.servers.gamingCount} · Stream: ${order.servers.streamingCount}</strong></div>
    <div class="summary-card"><span>App Modules</span><strong>${order.modules.length} selected</strong></div>
    <div class="summary-card"><span>Monetization</span><strong>${monLabels[order.monetization.model] || order.monetization.model}</strong></div>
    <div class="summary-card"><span>Design Theme</span><strong>${order.branding.themePreset.replace("_", " ")}</strong></div>
  `;
}

function formatElapsed(seconds) {
  const m = String(Math.floor(seconds / 60)).padStart(2, "0");
  const s = String(seconds % 60).padStart(2, "0");
  return `${m}:${s}`;
}

async function pollBuildStatus(jobId, statusEl, appName) {
  const startedAt = Date.now();
  let lastMessage = "Preparing build...";
  let stopped = false;

  const renderProgress = () => {
    if (stopped) return;
    const elapsedSec = Math.floor((Date.now() - startedAt) / 1000);
    statusEl.className = "status-banner info";
    statusEl.innerHTML = `
      <div style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap;">
        <span><strong>${lastMessage}</strong> (Job: <code>${jobId}</code>)</span>
        <span style="font-weight:600;">Elapsed: ${formatElapsed(elapsedSec)} · Est: ~1–3 min</span>
      </div>
    `;
  };

  renderProgress();
  const timerId = setInterval(renderProgress, 1000);

  const poll = async () => {
    try {
      const res = await fetch(`${FYREWAY_BUILD_API_BASE}/api/whitelabel/status?id=${jobId}`);
      if (!res.ok) {
        if (!stopped) setTimeout(poll, 3000);
        return;
      }
      const data = await res.json();

      if (data.status === "ready") {
        stopped = true;
        clearInterval(timerId);
        const totalSec = Math.max(1, Math.floor((Date.now() - startedAt) / 1000));
        const downloadUrl = data.downloadUrl || `${FYREWAY_BUILD_API_BASE}/api/whitelabel/download?id=${jobId}`;
        const safeSlug = (appName || "fyreway-vpn").toLowerCase().replace(/[^a-z0-9]/g, "") || "vpn";

        statusEl.className = "status-banner success";
        statusEl.innerHTML = `
          <div><strong>Build Complete in ${formatElapsed(totalSec)}!</strong> Your <b>${appName || "VPN"}</b> APK is ready for testing.</div>
          <div style="margin-top:12px;display:flex;gap:10px;flex-wrap:wrap;align-items:center;">
            <a href="${downloadUrl}" download="${safeSlug}-release.apk" class="btn btn-primary" style="display:inline-block;text-decoration:none;">
              Download Testing APK
            </a>
            <button type="button" class="btn btn-secondary" id="copyApkLinkBtn">Copy Download Link</button>
          </div>
          <div style="margin-top:8px;font-size:12px;word-break:break-all;">
            Direct Link: <a href="${downloadUrl}" style="color:#93c5fd;">${downloadUrl}</a>
          </div>
        `;

        document.getElementById("copyApkLinkBtn")?.addEventListener("click", async (ev) => {
          await navigator.clipboard.writeText(downloadUrl);
          ev.target.textContent = "Copied!";
          setTimeout(() => (ev.target.textContent = "Copy Download Link"), 1600);
        });
        return;
      }

      if (data.status === "error") {
        stopped = true;
        clearInterval(timerId);
        statusEl.className = "status-banner info";
        statusEl.textContent = data.message || "Build encountered an error.";
        return;
      }

      if (data.message) lastMessage = data.message;
      setTimeout(poll, 3000);
    } catch {
      if (!stopped) setTimeout(poll, 4000);
    }
  };
  poll();
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const order = buildUserOrderPayload();
  const statusEl = document.getElementById("submitStatus");
  statusEl.hidden = false;
  statusEl.className = "status-banner info";
  statusEl.textContent = "Submitting your app request & starting build (Est: ~1–3 min)...";

  try {
    const res = await fetch(`${FYREWAY_BUILD_API_BASE}/api/whitelabel/orders`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(order),
    });

    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || `HTTP ${res.status}`);
    if (data.jobId) {
      pollBuildStatus(data.jobId, statusEl, order.app.name);
    } else {
      statusEl.className = "status-banner success";
      statusEl.textContent = "Thank you! Your app request has been received.";
    }
  } catch (err) {
    statusEl.className = "status-banner info";
    statusEl.textContent = err.message || "Could not reach build server.";
  }
});

const DEMO_COUNTER_KEY = "fyreway_demo_proto_num";
const THEME_CYCLE = ["cyber_dark", "neon_gaming", "minimal_light", "emerald_shield"];

function applyDemoDefaults(increment = false) {
  let num = Number(localStorage.getItem(DEMO_COUNTER_KEY) || "1");
  if (increment) {
    num += 1;
    localStorage.setItem(DEMO_COUNTER_KEY, String(num));
  }

  document.getElementById("devName").value = "Danyal";
  document.getElementById("devEmail").value = "danyal@fyreway.com";
  document.getElementById("appName").value = `DanyalVPN_prototype${num}`;

  document.getElementById("freeServersCount").value = 3 + (num % 5);
  document.getElementById("premiumServersCount").value = 20 + num * 2;
  document.getElementById("gamingServersCount").value = 4 + (num % 4);
  document.getElementById("streamingServersCount").value = 5 + (num % 4);

  const presetKey = THEME_CYCLE[(num - 1) % THEME_CYCLE.length];
  const presetRadio = document.querySelector(`input[name="themePreset"][value="${presetKey}"]`);
  if (presetRadio) {
    presetRadio.checked = true;
    presetRadio.dispatchEvent(new Event("change"));
  }

  if (currentStep === 5) renderReview();
}

document.getElementById("autoFillBtn")?.addEventListener("click", () => {
  applyDemoDefaults(true);
});

applyDemoDefaults(false);
goToStep(1);
