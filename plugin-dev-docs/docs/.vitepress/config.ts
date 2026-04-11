import { defineConfig } from "vitepress";

export default defineConfig({
  lang: "zh-CN",
  title: "Breeze 插件开发文档",
  description: "面向第三方作者的 Breeze 插件开发手册",
  lastUpdated: true,
  themeConfig: {
    nav: [
      { text: "快速开始", link: "/guide/quick-start" },
      { text: "API 契约", link: "/guide/plugin-api-contract" },
      { text: "调试与发布", link: "/guide/debug-and-release" }
    ],
    sidebar: [
      {
        text: "开始",
        items: [
          { text: "文档首页", link: "/" },
          { text: "快速开始", link: "/guide/quick-start" },
          { text: "生命周期与结构", link: "/guide/runtime-and-structure" }
        ]
      },
      {
        text: "接口协议",
        items: [
          { text: "插件 API 契约", link: "/guide/plugin-api-contract" },
          { text: "API 响应样例", link: "/guide/api-examples" },
          { text: "Scheme 设计", link: "/guide/scheme-design" }
        ]
      },
      {
        text: "调试与交付",
        items: [
          { text: "调试与发布", link: "/guide/debug-and-release" },
          { text: "交付检查清单", link: "/guide/checklist" }
        ]
      }
    ],
    socialLinks: [{ icon: "github", link: "https://github.com/deretame/Breeze" }]
  }
});
