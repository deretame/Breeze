<script>
  import { getCurrentWindow } from "@tauri-apps/api/window";
  import "../app.css";

  const appWindow = getCurrentWindow();

  function minimize() {
    appWindow.minimize();
  }

  function close() {
    appWindow.close();
  }
</script>

<div class="app-layout">
  <div class="titlebar">
    <div data-tauri-drag-region class="title">Breeze 安装程序</div>
    <div data-tauri-drag-region class="spacer"></div>
    <div class="window-controls">
      <button
        onclick={minimize}
        class="control-btn minimize"
        aria-label="Minimize"
      >
        <svg
          width="10"
          height="1"
          viewBox="0 0 10 1"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <rect width="10" height="1" rx="0.5" fill="currentColor" />
        </svg>
      </button>
      <button onclick={close} class="control-btn close" aria-label="Close">
        <svg
          width="10"
          height="10"
          viewBox="0 0 10 10"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M9.35355 0.646447C9.54882 0.841709 9.54882 1.15829 9.35355 1.35355L5.70711 5L9.35355 8.64645C9.54882 8.84171 9.54882 9.15829 9.35355 9.35355C9.15829 9.54882 8.84171 9.54882 8.64645 9.35355L5 5.70711L1.35355 9.35355C1.15829 9.54882 0.841709 9.54882 0.646447 9.35355C0.451184 9.15829 0.451184 8.84171 0.646447 8.64645L4.29289 5L0.646447 1.35355C0.451184 1.15829 0.451184 0.841709 0.646447 0.646447C0.841709 0.451184 1.15829 0.451184 1.35355 0.646447L5 4.29289L8.64645 0.646447C8.84171 0.451184 9.15829 0.451184 9.35355 0.646447Z"
            fill="currentColor"
          />
        </svg>
      </button>
    </div>
  </div>

  <div class="content">
    <slot></slot>
  </div>
</div>

<style>
  .app-layout {
    display: flex;
    flex-direction: column;
    height: 100vh;
    background-color: #f6f6f6;
    color: #0f0f0f;
    border: 1px solid #ddd; /* Subtle border for frameless window */
    border-radius: 8px; /* Optional rounded corners */
    overflow: hidden;
  }

  .titlebar {
    height: 32px;
    background: #ffffff;
    user-select: none;
    display: flex;
    justify-content: space-between;
    align-items: center;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 1000;
    padding-left: 12px;
    border-bottom: 1px solid #eee;
  }

  .title {
    font-size: 12px;
    font-weight: 600;
    color: #333;
    padding-right: 12px;
  }

  .spacer {
    flex: 1;
    height: 100%;
  }

  .window-controls {
    display: flex;
    height: 100%;
  }

  .control-btn {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 46px;
    height: 100%;
    border: none;
    background: transparent;
    cursor: pointer;
    color: #333;
    transition: background-color 0.2s;
  }

  .control-btn:hover {
    background-color: #e5e5e5;
  }

  .control-btn.close:hover {
    background-color: #e81123;
    color: white;
  }

  .content {
    margin-top: 32px; /* Offset for titlebar */
    flex: 1;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  @media (prefers-color-scheme: dark) {
    .app-layout {
      background-color: #1f1f1f;
      color: #f6f6f6;
      border-color: #333;
    }

    .titlebar {
      background: #2f2f2f;
      border-bottom-color: #111;
    }

    .title {
      color: #eee;
    }

    .control-btn {
      color: #eee;
    }

    .control-btn:hover {
      background-color: #444;
    }

    .control-btn.close:hover {
      background-color: #c42b1c;
    }
  }
</style>
