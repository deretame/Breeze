<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
  import { getCurrentWindow } from "@tauri-apps/api/window";
  import { open } from "@tauri-apps/plugin-dialog";
  import { onMount } from "svelte";

  let installPath = $state("");
  let createShortcut = $state(true);
  let statusMessage = $state("");
  let isInstalling = $state(false);
  let isComplete = $state(false);

  onMount(async () => {
    try {
      installPath = await invoke("get_default_install_path");
    } catch (error) {
      console.error("Failed to get default path:", error);
      statusMessage = "无法获取默认路径";
    }
  });

  async function browse() {
    try {
      const selected = await open({
        directory: true,
        multiple: false,
        defaultPath: installPath || undefined,
      });

      if (selected && typeof selected === "string") {
        installPath = selected;
      }
    } catch (error) {
      console.error("Failed to open dialog:", error);
      statusMessage = "无法打开选择对话框";
    }
  }

  async function install() {
    if (!installPath) {
      statusMessage = "请选择安装路径";
      return;
    }

    isInstalling = true;

    const delay = (ms: number) =>
      new Promise((resolve) => setTimeout(resolve, ms));

    try {
      // Step 0: Try to close running app
      statusMessage = "正在尝试关闭运行中的软件...";
      await delay(3000);
      await invoke("try_shutdown_app");

      // Step 1: Extract files
      statusMessage = "正在安装...";
      await delay(300);
      const exePath: string = await invoke("perform_install", {
        installPath,
      });

      // Step 2: Create shortcut if requested
      if (createShortcut) {
        statusMessage = "正在创建桌面快捷方式...";
        await delay(500);
        await invoke("create_shortcut", {
          targetPath: exePath,
          shortcutName: "Breeze",
        });
      }

      // Step 3: Save install path for next time
      statusMessage = "正在保存安装信息...";
      await delay(500);
      await invoke("save_install_path", { installPath });

      await delay(300);
      statusMessage = "安装完成！";
      isComplete = true;
    } catch (error) {
      console.error("Installation failed:", error);
      statusMessage = `安装失败: ${error}`;
    } finally {
      isInstalling = false;
    }
  }

  function finish() {
    getCurrentWindow().close();
  }
</script>

<main class="container">
  <div class="main-content">
    <div class="header">
      <div class="icon-placeholder">
        <!-- Replace with actual app icon if available -->
        <svg
          width="64"
          height="64"
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M12 22C17.5228 22 22 17.5228 22 12C22 6.47715 17.5228 2 12 2C6.47715 2 2 6.47715 2 12C2 17.5228 6.47715 22 12 22Z"
            stroke="#3b82f6"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M8 12L11 15L16 9"
            stroke="#3b82f6"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
      </div>
      <h1>安装 Breeze</h1>
      <p class="subtitle">欢迎使用 Breeze 安装向导</p>
    </div>

    <div class="installer-form">
      <div class="form-group">
        <label for="install-path">安装路径</label>
        <div class="input-group">
          <input
            id="install-path"
            type="text"
            placeholder="C:\..."
            bind:value={installPath}
            disabled={isInstalling || isComplete}
          />
          <button
            class="browse-btn"
            onclick={browse}
            disabled={isInstalling || isComplete}>浏览</button
          >
        </div>
      </div>

      <div class="form-group checkbox-group">
        <label class="checkbox-label">
          <input
            id="create-shortcut"
            type="checkbox"
            bind:checked={createShortcut}
            disabled={isInstalling || isComplete}
          />
          <span class="custom-checkbox"></span>
          创建桌面快捷方式
        </label>
      </div>

      <div class="actions">
        {#if isComplete}
          <button class="install-btn complete" onclick={finish}>
            完成安装
          </button>
        {:else}
          <button class="install-btn" onclick={install} disabled={isInstalling}>
            {isInstalling ? "安装中..." : "立即安装"}
          </button>
        {/if}
      </div>

      {#if statusMessage}
        <p
          class="status {statusMessage.includes('失败') ? 'error' : 'success'}"
        >
          {statusMessage}
        </p>
      {/if}
    </div>
  </div>

  <div class="footer">
    <p>继续操作即视为您同意服务条款。</p>
  </div>
</main>

<style>
  :root {
    --primary-color: #3b82f6;
    --primary-hover: #2563eb;
    --bg-color: #ffffff;
    --text-color: #1f2937;
    --text-secondary: #6b7280;
    --border-color: #e5e7eb;
    --input-bg: #f9fafb;
  }

  @media (prefers-color-scheme: dark) {
    :root {
      --bg-color: #1f2937;
      --text-color: #f3f4f6;
      --text-secondary: #9ca3af;
      --border-color: #374151;
      --input-bg: #111827;
    }
  }

  .container {
    display: flex;
    flex-direction: column;
    /* Removed justify-content: center; */
    align-items: center;
    height: 100%;
    padding: 2rem;
    box-sizing: border-box;
    font-family: "Segoe UI", "Microsoft YaHei", sans-serif;
  }

  .main-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 100%;
  }

  .header {
    text-align: center;
    margin-bottom: 2rem;
  }

  .icon-placeholder {
    margin-bottom: 1rem;
    display: flex;
    justify-content: center;
  }

  h1 {
    font-size: 1.8rem;
    font-weight: 600;
    margin: 0;
    color: var(--text-color);
  }

  .subtitle {
    color: var(--text-secondary);
    margin-top: 0.5rem;
    font-size: 1rem;
  }

  .installer-form {
    width: 100%;
    max-width: 420px;
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .form-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  label {
    font-size: 0.9rem;
    font-weight: 500;
    color: var(--text-color);
  }

  .input-group {
    display: flex;
    gap: 0.5rem;
  }

  input[type="text"] {
    flex: 1;
    padding: 0.6rem 0.8rem;
    border: 1px solid var(--border-color);
    border-radius: 6px;
    background: var(--input-bg);
    color: var(--text-color);
    font-size: 0.95rem;
    outline: none;
    transition: border-color 0.2s;
  }

  input[type="text"]:focus {
    border-color: var(--primary-color);
    box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.1);
  }

  .browse-btn {
    padding: 0 1rem;
    background: transparent;
    border: 1px solid var(--border-color);
    border-radius: 6px;
    color: var(--text-color);
    cursor: pointer; /* Changed to pointer even if disabled for now to look better, but visually disabled */
    transition: background 0.2s;
  }

  .browse-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .checkbox-group {
    flex-direction: row;
    align-items: center;
  }

  .checkbox-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
    user-select: none;
  }

  input[type="checkbox"] {
    accent-color: var(--primary-color);
    width: 1.1rem;
    height: 1.1rem;
  }

  .actions {
    margin-top: 1rem;
  }

  .install-btn {
    width: 100%;
    padding: 0.8rem;
    background-color: var(--primary-color);
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition:
      background-color 0.2s,
      transform 0.1s;
    box-shadow:
      0 4px 6px -1px rgba(0, 0, 0, 0.1),
      0 2px 4px -1px rgba(0, 0, 0, 0.06);
  }

  .install-btn:hover:not(:disabled) {
    background-color: var(--primary-hover);
  }

  .install-btn:active:not(:disabled) {
    transform: translateY(1px);
  }

  .install-btn:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .install-btn.complete {
    background-color: #10b981;
  }

  .install-btn.complete:hover {
    background-color: #059669;
  }

  .status {
    text-align: center;
    font-size: 0.9rem;
    margin: 0;
  }

  .status.success {
    color: #10b981;
  }

  .status.error {
    color: #ef4444;
  }

  .footer {
    margin-top: auto;
    font-size: 0.75rem;
    color: var(--text-secondary);
    opacity: 0.6;
    padding: 1rem 0;
  }
</style>
