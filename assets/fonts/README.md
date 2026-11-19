# 游戏中文字体

`NotoSansCJKsc-Regular.otf` 为 Noto Sans CJK SC Regular 的完整字库，来自运行环境的 Debian `fonts-noto-cjk` 包中 `NotoSansCJK-Regular.ttc`，使用 fontTools 从该集合提取第 2 个字体（SC）并保存为独立 OpenType 文件。文件包含原有字形和字体元数据；授权文本见同目录 `OFL.txt`。

- 字体文件 SHA-256：`edeeddd98b2c282f7c85a766f2b74f97e99e29dd62f4a55e2c0438c3beac56c7`
- 来源字体集合 SHA-256：`b76b0433203017ca80401b2ee0dd69350349871c4b19d504c34dbdd80541690a`
- 提取方式：`TTFont("NotoSansCJK-Regular.ttc", fontNumber=2).save("NotoSansCJKsc-Regular.otf")`

生活岛、竞技岛共享该字库。执行 `python3 tools/check_font_coverage.py` 检查游戏文案；Web 打包准备流程也执行此检查。检查程序不是实际渲染验收的替代品，新增动态文字、平台字体回退和文字布局仍须实际验证。
