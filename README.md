# TuyaPet  桌面宠物

一只可爱的小鸭鸭桌宠，漂浮在你的 macOS 桌面上。

## 一键安装

```bash
git clone https://github.com/jianglei0201/tuya-pet.git
cd tuya-pet
bash install.sh
```

小鸭子会自动出现在屏幕上！

## 功能

- 🎨 **换装** — 点击身体切换 4 套衣服
- 💬 **聊天** — 点击头部随机对话，右键菜单选择心情
- 💃 **跳芭蕾** — 右键 → 跳芭蕾舞
- - 🌀 **转圈** — 右键 → 转圈（3D 换装动画）
- 😴 **睡觉** — 右键 → 睡觉（30秒无操作也会自动睡）
- 🔍 **变大/变小** — 右键 → 变大（高清放大）
- 💧 **喝水提醒** — 每 30 分钟提醒喝水
- ⌨️ **打字检测** — 打字时自动切换姿态
- 🌤️ **天气** — 聊天选项查看实时天气
- 🚶 **走路** — 点击脚部走路动画

## 自定义形象

想换成自己的角色？准备好图片后运行：

```bash
bash install.sh --images ~/我的图片/
```

### 图片要求

| 文件名 | 说明 | 要求 |
|--------|------|------|
| `default.png` | 默认站姿 | 必须，透明背景 PNG，建议 500px 宽 |
| `happy.png` | 开心表情 | 可选 |
| `tired.png` | 疲惫表情 | 可选 |
| `hungry.png` | 饿了表情 | 可选 |
| `bored.png` | 无聊表情 | 可选 |
| `sleep.png` | 睡觉状态 | 可选 |
| `typing.png` | 打字状态 | 可选 |
| `dress.png` | 换装1 | 可选 |
| `dress2.png` | 换装2 | 可选 |
| `dress3.png` | 换装3 | 可选 |

所有图片建议：透明背景 PNG，宽度 500px，角色底部对齐。

## 自定义设置

- **修改天气城市**：编辑 `src/server.js`，找到 `wttr.in/Hangzhou` 改为你的城市
- **修改聊天回复**：编辑 `src/pet-window.html`，找到 `getReply` 函数
- **修改 App 名称**：`bash install.sh MyPetName`

## 系统要求

- macOS 12+
- Xcode Command Line Tools（`xcode-select --install`）
- Node.js（`brew install node`）
> **首次打开提示"无法验证开发者"？**
> 右键点击 `TuyaPet.app` → 选择「打开」→ 再点「打开」即可。只需操作一次，之后双击正常打开。

## 卸载

```bash
rm -rf /Applications/TuyaPet.app
rm -rf ~/.kitty-pet
```

## 目录结构

```
tuya-pet/
├── install.sh        # 一键安装
├── build.sh          # 编译脚本
├── images/           # 图片资源（换皮改这里）
├── src/
│   ├── app.swift     # macOS 原生窗口
│   ├── pet-window.html  # UI + 动画 + 交互
│   └── server.js     # HTTP 服务（天气 API）
└── output/           # 编译产物
```
