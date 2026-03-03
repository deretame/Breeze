# Git Hooks 与换行符设置说明

本仓库已通过 `.gitattributes` 和 `.editorconfig` 统一换行符策略（仓库内文本文件统一为 LF）。

为了让本地提交行为一致，请在每个本地克隆仓库执行一次以下命令：

```bash
git config core.hooksPath .githooks
git add --renormalize .
```

## 为什么要做这两步

- `git config core.hooksPath .githooks`
  - 启用仓库内的 Git hooks（包括 pre-commit 检查）。
  - 这是仓库级配置，只对当前本地仓库生效。

- `git add --renormalize .`
  - 按 `.gitattributes` 规则重新规范化已跟踪文件的行尾。
  - 建议只在首次接入该规则时执行一次。

## 重要提醒

- 上述设置不会自动应用到你机器上的其他仓库。
- 你在其他仓库也需要分别执行对应配置。

## pre-commit 行为

本仓库 pre-commit 会在提交前自动按 `.gitattributes` 对已暂存文件做一次规范化：

- 自动执行：`git add --renormalize -- <staged_files>`
- 若规范化后仍有有效改动：正常继续提交
- 若规范化后只剩换行符噪音：终止提交并给出中英双语提示

提示示例：

- `Only line-ending noise was staged; auto-normalized and unstaged.`
- `仅检测到换行符噪音，已自动规范并从暂存区移除。`
- `No effective changes left to commit.`
- `没有可提交的有效改动。`
