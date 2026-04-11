# 交付检查清单

## 代码契约

- [ ] `export default` 包含所有宿主会调用的 `fnPath`
- [ ] 核心五件套已实现：`getInfo/searchComic/getComicDetail/getChapter/fetchImageBytes`
- [ ] 需要兼容命名的函数已提供别名导出

## 数据结构

- [ ] 搜索列表 `data.items[]` 的字段完整（`id/title/cover/metadata/raw`）
- [ ] 详情页 `data.normal.comicInfo + data.normal.eps` 结构完整
- [ ] 章节 `data.chapter.docs[]` 提供 `id/name/path/url`
- [ ] 所有 `extern` 透传逻辑闭环

## 业务流程

- [ ] 登录流程（`getLoginBundle/loginWithPassword`）可用
- [ ] 收藏/点赞流程（`toggleFavorite/toggleLike`）可用
- [ ] 评论流（若实现）支持分页和回复
- [ ] 过滤器（若实现）能正确下发 `core/extern`

## 稳定性

- [ ] 网络请求统一超时与错误转换
- [ ] 登录过期返回 unauthorized 结构化错误
- [ ] `fetchImageBytes` 支持二进制回传
- [ ] 调试模式与发布模式都跑通过

## 发布

- [ ] bundle 与插件 UUID 对齐
- [ ] 版本号已更新
- [ ] 至少完成一次真实设备完整回归（首页 -> 搜索 -> 详情 -> 阅读）
- [ ] 变更记录已写清楚（新增能力、兼容性影响、已知限制）
