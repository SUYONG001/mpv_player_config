# 🎬 mpv 播放器部署与配置还原指南

> （uosc 与 ModernX 共存架构 + 全量中文注释版）
>
> **适用平台**：Windows 主推（兼顾 macOS / Linux 跨平台）
>
> **核心设计**：ModernX 全面负责主界面交互 + uosc 专精右键功能菜单

---

## 📖 目录

- [一、核心架构与特性](#一核心架构与特性)
  - [1.1 uosc 与 ModernX 分工](#11-uosc-与-modernx-分工)
  - [1.2 分辨率自适应 Profile 与配置作用域](#12-分辨率自适应-profile-与配置作用域)
  - [1.3 音频专项优化](#13-音频专项优化)
  - [1.4 解码方式：硬解与软解](#14-解码方式硬解与软解)
  - [1.5 统计面板：英文 / 中文切换](#15-统计面板英文--中文切换)
  - [1.6 网络串流与体验优化](#16-网络串流与体验优化)
- [二、零基础部署步骤](#二零基础部署步骤)
- [三、功能验证清单](#三功能验证清单)
- [四、快捷键速查表](#四快捷键速查表)
- [五、脚本与配置速查](#五脚本与配置速查)
  - [5.1 脚本与扩展职能](#51-脚本与扩展职能)
  - [5.2 配置文件职能](#52-配置文件职能)
- [六、进度条主题色库](#六进度条主题色库)
- [七、跨平台与维护指南](#七跨平台与维护指南)

---

## 一、核心架构与特性

### 1.1 uosc 与 ModernX 分工

为解决两大主流 UI 框架界面重叠与功能冲突的问题，本方案实施了清晰的视觉与功能分工：

* **ModernX（`modernx.lua`）—— 主界面与交互渲染**
  * 全权负责底部进度条、悬浮控制栏、顶部标题栏的视觉呈现。
  * 深度联动 `thumbfast.lua` 抓取进度条预览缩略图。
  * 接管播放器空闲时的 Logo 展示与纯音频状态指示。
  * **网络流防白框机制**：内置网络流自动识别逻辑，播放网络视频时主动跳过缩略图背景绘制，杜绝空白矩形残留。

* **uosc 框架 —— 功能菜单与辅助指示引擎**
  * 全权负责鼠标右键与 <kbd>Tab</kbd> 唤出的多级半透明上下文菜单（采用**双层统一 Emoji** 极简美化排版）。
  * 提供播放列表导航面板、音轨/字幕直选面板、在线串流快速入口与章节跳转列表。
  * **精准元素保留**：通过 `uosc.conf` 仅保留无边框细线边框（`window_border`）、右侧垂直音量滑块（`volume`）、流媒体缓冲旋转动画（`buffering_indicator`）及暂停闪烁图标（`pause_indicator`）。
  * **精准元素剔除**：强制禁用顶栏（`top_bar`）、进度条（`timeline`）、控制栏（`controls`）、空闲图标（`idle_indicator`）与音频指示（`audio_indicator`），彻底杜绝与 ModernX 发生视觉冲突。

<img width="962" height="563" alt="视频预览 (2)" src="[https://github.com/user-attachments/assets/ac583fd8-816c-4377-a05f-e3ba96890ceb](https://github.com/user-attachments/assets/ac583fd8-816c-4377-a05f-e3ba96890ceb)" />

> **实机效果预览 · 视频播放协同**：左侧为鼠标右键唤出的 **uosc 半透明深色菜单**（支持倍速、轨道、滤镜快速直选），底部为 **ModernX 进度条与控制栏**，鼠标悬停在时间轴上时，由 **Thumbfast** 秒级拉起高清原画缩略图，整体界面清爽无重叠。

### 1.2 分辨率自适应 Profile 与配置作用域

> **什么是 Profile？**
> Profile（配置文件）是 mpv 的原生机制，用于将一组设置打包成一个"预设"，可以手动切换，也可以根据条件自动触发。
> 本方案使用的是 **Auto Profile（条件自动 Profile）**：通过 `profile-cond=` 指定触发条件（如视频分辨率、帧率、编码），一旦条件满足，Profile 内的设置会自动生效，无需手动干预。

本方案全面采用原生视频分辨率进行针对性优化：

* **中等分辨率区间（`720P ≤ height < 2160`）**：自动激活 2 轮强效去色带（Deband），抚平动画雾面与暗部渐变断层。
* **超高清区间（`width ≥ 2560`）**：自动关闭去色带，完整保留 2K/4K 原盘高码率原生细节与纹理。
* **低清老旧视频（`height ≤ 720`）**：自动提升抗振铃（Anti-ringing）系数至 `0.8`，有效抑制压缩杂讯与边缘光晕。

> ⚠️ **关键规则：全局配置与 Profile 顺序**
> mpv 配置具有向下贪婪捕获特性，一旦声明了 `[Profile-Name]`，下方所有代码都会被归入该 Profile 作用域。
> 因此，**所有的常规设置、网络缓存控制与全局开关，必须严格放置在 `mpv.conf` 的上方，Auto Profile 必须放置在整个文件的最末尾！**

### 1.3 音频专项优化

* **有封面音频**：自动居中展示内嵌封面或同目录封面图，按 `audio_scale_height` 缩放。
* **无封面音频**：`visualizer.lua` 自动挂载 `showcqtbar` 滤镜，渲染音阶标尺彩虹频谱。
* **音量持久化记忆**：`save-volume.lua` 自动记忆退出时的音量状态，冷启动不重置。
* **拖动进度条防爆音**：内置进度寻道防刺耳抑制，跳转时主动平滑降噪，消除切换片段时的爆音现象。
* **窗口标题自定义**：`title_filename.lua` 读取 `title_filename.conf`，默认显示内嵌标题（无则回退文件名）。

<img width="482" height="293" alt="音频预览" src="[https://github.com/user-attachments/assets/2d2e779c-2b1c-4c0f-8b5a-aaf3ee19b6b9](https://github.com/user-attachments/assets/2d2e779c-2b1c-4c0f-8b5a-aaf3ee19b6b9)" />

> **实机效果预览 · 音频频谱可视化**：播放无封面音频文件（如 `.wav`）时，`visualizer.lua` 自动挂载 `showcqtbar` 滤镜，以音阶（C/D/E/F/G/A/B）标尺动态呈现高精度彩虹频谱，同时底层自动切断无意义的画面插值与去色带计算，大幅节省 GPU 资源。

### 1.4 解码方式：硬解与软解

mpv 支持两种视频解码方式，各有适用场景：

| 对比项 | 硬解（硬件解码） | 软解（软件解码） |
| :--- | :--- | :--- |
| **原理** | 利用显卡专用解码电路（NVDEC / D3D11VA 等） | 利用 CPU 通用计算解码 |
| **CPU 占用** | 极低 | 较高，取决于分辨率和编码 |
| **功耗** | 低，适合笔记本续航 | 高，高负载时风扇可能起飞 |
| **兼容性** | 依赖显卡支持，老旧或冷门编码可能不支持 | 几乎支持所有格式 |
| **画质** | 通常足够好，部分场景略逊于软解 | 理论最优，但差异通常难以察觉 |

**如何查看当前是硬解还是软解？**

* **方法一**：播放视频时按 <kbd>i</kbd> 调出统计面板，查看 `Video` 一栏。
  * 若显示 `[nvdec]`、`[d3d11va]` 或带有 `hardware` 字样 → **硬解**
  * 若只显示编码名称（如 `H.264 / AVC`）→ **软解**

* **方法二**：按 <kbd>~</kbd> 打开控制台，输入以下命令并回车：
  ```lua
  print(mp.get_property("hwdec-current"))
  ```
  * 返回 `no` → **软解**
  * 返回 `nvdec`、`d3d11va` 等 → **硬解**

当前配置默认使用 `hwdec=auto-safe`，它会自动选择最稳妥的硬解接口（如 `d3d11va`），遇到不支持的格式则回退软解，兼顾兼容性与性能。

### 1.5 统计面板：英文 / 中文切换

按 <kbd>i</kbd> 唤出的性能统计面板，默认使用 **mpv 内置的英文版本**。

本仓库额外提供了一份**中文增强版** `stats.lua`（含 CPU / GPU 实时占用率显示）。

**启用方法：**

打开 `portable_config/mpv.conf`，找到这一行：

```ini
#load-stats-overlay=no
```

去掉行首的 `#`，改为：

```ini
load-stats-overlay=no
```

保存后**完全关闭 mpv 再重新打开**（热加载不会生效），按 <kbd>i</kbd> 即可看到中文面板。

<img width="962" height="563" alt="中文统计面板" src="[https://github.com/user-attachments/assets/67af903a-dce1-4dcc-85a9-86fefc967197](https://github.com/user-attachments/assets/67af903a-dce1-4dcc-85a9-86fefc967197)" />

> **实机效果预览 · 中文统计面板**：所有标签（文件、视频、音频、丢帧、硬解状态等）均为中文显示，顶部额外增加 CPU / GPU 实时占用率行，方便排查性能瓶颈。

> **注意**：启用中文版后，mpv 内置的英文面板会被禁用，两者不能同时生效。

### 1.6 网络串流与体验优化

本方案针对 Bilibili、YouTube、IPTV 及网络直链播放进行了深度优化：

* **联动 yt-dlp 极速串流**：通过集成 `yt-dlp`，支持直接拖拽或从剪贴板加载主流网站视频与在线直播源。
* **全局流媒体防卡顿缓存**：
  * 强制分配 256MB 前向预读缓冲（`demuxer-max-bytes=256MiB`）与 100MB 回退后向缓存（`demuxer-max-back-bytes=100MiB`），即便网络微弱波动也能平滑流畅。
  * 针对弱网环境配置了 15 秒超时重连与 `reconnect` 机制。
* **清晰度策略保护**：预设 `ytdl-format="bestvideo[height<=?1080]+bestaudio/best"`，默认拉取最佳 1080P，避免网络不佳时默认请求 4K 导致严重卡顿。
* **缩略图白框根治补丁**：
  * 流媒体寻道需要反复发起 HTTP Range 请求，子进程频繁并发极易触发反爬或超时。
  * 本方案将 `thumbfast.conf` 设定为 `network=no`（本地优先），同时在 `modernx.lua` 中加入 `demuxer-via-network` 状态探测，网络流下完全隐藏空白底框，仅保留清爽的时间戳文字提示。

---

## 二、零基础部署步骤

### 1. 下载主程序并解压

* 从 [mpv 官方 GitHub Releases](https://github.com/mpv-player/mpv/releases) 获取最新的 64 位 Windows 构建包。
* 解压至本地安装目录（推荐路径：`C:\mpv\`）。

### 2. 导入便携配置文件

* 将本仓库的所有内容整体作为 `portable_config` 文件夹放入 `C:\mpv\` 根目录下。
* 此时目录结构应形如：
  ```text
  C:\mpv\
  ├── mpv.exe
  ├── ...
  └── portable_config\
      ├── mpv.conf
      ├── input.conf
      ├── yt-dlp.exe          <-- 注意：需要按第 3 步操作！
      ├── fonts\
      ├── scripts\
      └── script-opts\
  ```

### 3. ⚠️ 关键步骤：移动 `yt-dlp.exe` 至 mpv 根目录

> **核心提示**：
> 本仓库为了方便一键打包分发，将 `yt-dlp.exe` 存放在了配置包内。
> 但 **mpv 在解析网络视频时，默认只会查找与 `mpv.exe` 同级的根目录**（或系统环境变量 PATH）。
> 
> **请务必操作**：将 `portable_config\yt-dlp.exe` **剪切或复制到上一级的 `C:\mpv\` 根目录下**（与 `mpv.exe` 处于同一目录层级）。

### 4. 校验并修正 `thumbfast.conf`

* 打开 `portable_config\script-opts\thumbfast.conf`。
* 确认 `mpv_path=` 指向当前设备上的实际绝对路径（默认推荐 `C:\mpv\mpv.exe`）。

### 5. （可选）关联文件格式

* 以管理员身份运行 mpv 目录下的 `mpv-register.bat` 即可一键绑定系统常见媒体格式。

---

## 三、功能验证清单

完成部署后，拖拽视频或粘贴网络链接进入播放器，依次核对：

* [ ] **画质与渲染**：按 <kbd>i</kbd> 开启性能面板，观察 `Dropped Frames`（丢帧数）为 0 或维持极低水准。
* [ ] **主界面交互**：鼠标移动到底部，ModernX 罗兰紫进度条顺畅上浮弹出。
* [ ] **本地缩略图**：播放本地视频时，光标在进度条上方滑动能够秒级渲染高清缩略图。
* [ ] **网络串流与防白框**：
  * 复制一段 YouTube / B站视频链接，在 mpv 界面按 <kbd>Ctrl</kbd> + <kbd>v</kbd> 顺畅开播。
  * 鼠标在网络视频进度条上滑动时，**仅出现时间提示，不出现任何空白卡顿方框**。
* [ ] **uosc 统一全量 Emoji 菜单**：点击鼠标右键或按 <kbd>Tab</kbd> 键，一级与二级菜单整齐对齐，且带有统一 Emoji 标示。
* [ ] **拖动防刺耳**：按住进度条拖动时音量自动平滑降低，松手后恢复正常。
* [ ] **音量持久记忆**：调节音量至 80%，关闭播放器重新打开，音量依然保持在 80%。
* [ ] **纯音频播放**：播放无封面音乐文件时，自动卸载画面后处理滤镜，并动态渲染彩虹色 CQT 频谱。

---

## 四、快捷键速查表

| 功能操作 | 默认按键绑定 | 归属模块 / 效果 |
| :--- | :--- | :--- |
| **暂停 / 继续** | <kbd>Space</kbd> / <kbd>鼠标左键</kbd> | 基础播控 |
| **全屏 / 窗口化** | <kbd>f</kbd> / <kbd>Enter</kbd> | 窗口状态切换 |
| **退出全屏** | <kbd>Esc</kbd> | 快捷退出全屏 |
| **音量调节** | <kbd>↑</kbd> / <kbd>↓</kbd> / <kbd>鼠标滚轮</kbd> | 步进 2% 调节（上限锁定 100%） |
| **静音切换** | <kbd>m</kbd> | 快速静音 |
| **微调进度** | <kbd>←</kbd> / <kbd>→</kbd> | 步进快退 / 快进 5 秒 |
| **大跨度跳转** | <kbd>Ctrl</kbd> + <kbd>←</kbd> / <kbd>→</kbd> | 步进快退 / 快进 60 秒 |
| **📋 播放剪贴板网址** | <kbd>Ctrl</kbd> + <kbd>v</kbd> | **一键解析剪贴板网络流 / 直播 / 视频并播放** |
| **字幕轨道选择** | <kbd>j</kbd> | 呼出 uosc 字幕直选菜单 |
| **音频轨道选择** | <kbd>a</kbd> | 呼出 uosc 音轨直选菜单 |
| **视频轨道选择** | <kbd>v</kbd> | 呼出 uosc 视频轨直选菜单 |
| **去色带开关** | <kbd>b</kbd> | 手动开/关 Deband 滤镜 |
| **性能统计监控** | <kbd>i</kbd> | 显示 / 隐藏 OSD 渲染监控与丢帧统计 |
| **主功能菜单** | <kbd>鼠标右键</kbd> / <kbd>Tab</kbd> | 唤出 / 收起 uosc 核心交互面板 |
| **退出程序** | <kbd>q</kbd> | 安全退出进程并保存播放进度 |

---

## 五、脚本与配置速查

### 5.1 脚本与扩展职能

| 脚本 / 组件 | 对应配置 | 核心职责 |
| :--- | :--- | :--- |
| **`yt-dlp.exe`** | 根目录组件 | 网络流媒体解析引擎，支持 YouTube、B站及网页串流嗅探 |
| **`uosc/main.lua`** | `script-opts/uosc.conf` | uosc 框架入口，负责右键多级 Emoji 菜单、播放列表、轨道选择等 |
| **`modernx.lua`** | `script-opts/osc.conf` | ModernX 主界面渲染，含网络流防白框补丁、底部进度条与控制栏 |
| **`thumbfast.lua`** | `script-opts/thumbfast.conf` | 本地优先的快速缩略图生成器 |
| **`autoload.lua`** | `script-opts/autoload.conf` | 自动扫描同目录文件并无缝加入连续播放列表 |
| **`playlistmanager.lua`** | `script-opts/playlistmanager.conf` | 播放列表管理器，支持排序、反转、随机、保存/加载 |
| **`visualizer.lua`** | `script-opts/visualizer.conf` | 纯音频播放时渲染高动态 CQT 彩虹柱状频谱 |
| **`quack.lua`** | `script-opts/quack.conf` | 拖动进度条时平滑降音，消除爆音杂音 |
| **`title_filename.lua`** | `script-opts/title_filename.conf` | 自定义窗口标题格式，支持 UTF-8 字符精准截断 |
| **`stats.lua`** | `script-opts/stats.conf` | 性能统计面板（提供 CPU / GPU 增强中文支持） |

### 5.2 配置文件职能

| 配置文件 | 相对路径 | 核心管理职责 |
| :--- | :--- | :--- |
| **`mpv.conf`** | `portable_config/` | 视频渲染驱动、网络大缓存控制、yt-dlp 参数与 Profile 自适应触发 |
| **`input.conf`** | `portable_config/` | 按键映射、在线串流调用规则与 uosc 双层 Emoji 菜单树定义 |
| **`osc.conf`** | `script-opts/` | ModernX 界面尺寸、滑动动画、按钮逻辑与十六进制 BGR 进度条色库 |
| **`uosc.conf`** | `script-opts/` | uosc 右键菜单外观、多语言配置、元素屏蔽黑名单（`disable_elements`） |
| **`thumbfast.conf`** | `script-opts/` | 缩略图生成上限尺寸、绝对调用路径及本地/网络模式开关 |
| **`visualizer.conf`** | `script-opts/` | 音频可视化类型选择、渲染画质分级与启用条件 |
| **`quack.conf`** | `script-opts/` | 拖动进度条时的降音幅度与恢复时长 |
| **`title_filename.conf`** | `script-opts/` | 窗口标题格式与 UTF-8 截断参数 |
| **`playlistmanager.conf`** | `script-opts/` | 播放列表管理器行为 |
| **`autoload.conf`** | `script-opts/` | 目录递归深度与文件隐藏过滤规则 |
| **`stats.conf`** | `script-opts/` | 性能统计面板悬浮停留时间及边距控制 |

---

## 六、进度条主题色库

ModernX 界面颜色遵循 **BGR（蓝-绿-红）** 排序。若需更换主题色，编辑 `portable_config/script-opts/osc.conf`，将末尾的 `seekbarfgcolor=` 改为下列代码：

| 分类系列 | 主题色彩名称 | BGR 配置代码 | 视觉效果描述 |
| :--- | :--- | :---: | :--- |
| **动漫主题系** | **罗兰电竞紫（当前默认）** | **`FF3399`** | **高饱和暗夜电竞紫，与 uosc 菜单浑然一体** |
| | 哔哩粉 | `9972FB` | 柔和粉红，二次元观影首选 |
| | 初音绿 | `BBC539` | 标志性葱绿配色，活力醒目 |
| | 初号机紫 | `A95178` | 沉稳微暗的经典机体配色 |
| **经典简约系** | 极简纯白 | `FFFFFF` | 纯净高亮，适合极简无干扰观影 |
| | 油管正红 | `0000FF` | 醒目鲜明，经典流媒体风格 |
| | 深海湛蓝 | `FF0000` | 沉稳冷峻，夜间使用不刺眼 |
| | 暖阳金橙 | `00B3FF` | 温和舒适，视觉辨识度高 |
| **高对比霓虹系** | 赛博青 | `FFFF00` | 亮眼电光青，暗色画面极易辨识 |
| | 警告黄 | `00FFFF` | 明黄撞色，进度定位清晰直接 |

---

## 七、跨平台与维护指南

1. **跨系统部署与平台微调**
   * **Windows 平台**：强制保留 `gpu-api=d3d11` 以获得最佳的资源开销与流畅度。
   * **macOS / Linux 平台**：在 `mpv.conf` 中将 `gpu-api=d3d11` 改为 `gpu-api=vulkan` 或直接注释该行。
2. **网络串流维护**
   * 若遇到部分网站视频无法播放，在终端或命令行中执行 `yt-dlp -U` 即可一键更新解析核心。
3. **版本迭代备份建议**
   * 修改快捷键或配置后，建议使用 Git 提交或通过 7-Zip 打包备份，并同步记录文档改动。