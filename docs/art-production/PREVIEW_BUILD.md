# 本地生活岛开发试玩构建

当前分支的 Web 导出可用下列环境变量产生独立试玩配置：

```sh
WONDER_ISLE_PREVIEW=1 WONDER_ISLE_COMMIT="$(git rev-parse HEAD)" tools/test_web_preview.sh
```

这会添加 `Development Preview` 标识和完整 commit SHA，使用 `user://qxisland_stage2_save_preview.json` 与 `wonder-isle-save-preview-v2`，并使用独立 PWA manifest/cache 名称。它只生成本地 `build/web`，不会发布到网站。

想在本机通过浏览器打开导出目录，可从项目根目录运行 `python3 -m http.server 8000 --directory build/web`，再访问 `http://127.0.0.1:8000/`。公开试玩地址需要独立域名/站点或独立仓库 Pages；不得把该目录部署到正式 Pages。
