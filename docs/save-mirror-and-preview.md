# 生活岛试玩版：存档镜像与发布边界

## 当前保护规则

- 正式版默认继续使用 `user://qxisland_stage2_save.json` 和原浏览器键 `wonder-isle-save-v1`，以便兼容已有正式进度。试玩版使用独立文件 `user://qxisland_stage2_save_preview.json` 与键 `wonder-isle-save-preview-v2`。
- 新镜像采用 `wonder-isle-save-mirror-v2` envelope，写入 namespace、整数 revision 与经过保存校验的 payload。WebFS 文件也记录 `_save_revision`。
- 启动时，两个候选都必须通过 JSON、当前 namespace 和 GameState schema 校验。revision 较高的有效快照胜出；相同版本以 WebFS 为准；损坏/未知 schema 的快照被忽略，不会自动清空或覆盖原文件。
- 浏览器保存使用独立 IndexedDB revision ledger 的 readwrite 事务。事务会串行读取当前修订号、比对并写入新镜像；同一事务内先同步更新 localStorage，再提交 ledger。两个并发标签最多一个通过修订检查，另一个收到冲突并提示刷新。localStorage 缓存短暂滞后时，较新 ledger 会修复镜像并拒绝旧标签。镜像写入成功后才写 Godot WebFS。
- IndexedDB 不可用、localStorage 被禁用、配额不足或数据不可解析时，保存失败并提示用户；不会退回到无并发保护的写入。浏览器端需有可用网站存储空间。Godot WebFS 文件写失败时，成功的 localStorage 镜像仍保留。
- 老版无 revision 的原始镜像按 revision 0 识别；同为 revision 0 时 WebFS 胜出，因为历史镜像无法证明比 WebFS 更新。首次新版本保存后将产生带 revision 的镜像。
- 显式“重新开始”是用户发起的新存档写入并递增 revision；普通启动不会因为坏镜像而覆盖磁盘存档。

## 仍需承认的边界

localStorage 与 IndexedDB 没有共同事务。IndexedDB ledger 的事务序列化负责跨标签并发修订；localStorage 是可同步读取的恢复镜像。刷新/退出若发生在镜像写入后，localStorage 可恢复该进度；本地浏览器若完全清除此 origin 的数据，网页无法恢复尚未同步的本地进度。若 IndexedDB 或 localStorage 不可用，游戏会停止保存并明确提示，不静默降级。

预览发布应使用独立 origin 最稳妥。若使用 GitHub Pages 的 `username.github.io/repository/`，虽然路径不同，二者依然共享浏览器 origin；代码因此分别隔离 WebFS 文件、镜像 key、PWA manifest 身份及 Cache Storage 命名前缀。预览 worker 只清理 preview 前缀，正式 worker 只清理 production 前缀。正式网站仍需保持当前线上部署，不从 feature 分支触发部署。

## 独立试玩部署方案

推荐创建 `zhuwd-dev/wonder-isle-preview` 独立仓库并配置该仓库自身的 GitHub Pages，发布路径与正式 `wonder-isle` 仓库分离，试玩从 `feature/life-island-polish` 构建。现有 workflow 当前只对 main/work branch 构建 Pages；不得直接把 feature branch push 到正式 Pages。此方案会新增外部仓库并修改 Pages 配置，因此需要项目所有者批准后才能创建/启用。仓库名和可用性也需现场确认。可选方案是提供独立静态托管 origin，仍需站点创建/部署授权。
