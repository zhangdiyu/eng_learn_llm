# Daily English Quest

通过 AI 对话练习，让日常英语变得自然流畅。

## 项目结构

```
eng_learn_llm/
  app/         Flutter Android 应用
  docs/        产品和技术文档
  build.sh     一键打包脚本
  PLAN.md      产品计划
```

## 快速开始

### 环境要求

- Flutter SDK 3.38+
- Android SDK
- JDK 17+

### 打包

```bash
# 构建 Debug APK
./build.sh

# 构建 Release APK
./build.sh release

# 构建 Android App Bundle
./build.sh appbundle

# 构建 Web (release，已带 gh-pages 守卫检查)
./build.sh web

# 清理构建产物
./build.sh clean
```

构建产物会输出到 `build/` 目录。

## 部署 Web 到 GitHub Pages

⚠️ 仅使用 `./build.sh web` 构建后再部署。脚本会做两道守卫：构建前检查 `lib/main.dart` 是核心 App、`web/` 目录完整；构建后检查产物 `main.dart.js` 包含 `deepseek` 且不含 `Flutter Demo Home Page`。这两个检查正是为了避免再次把 Flutter 默认计数器 Demo 推到线上。

```bash
# 1. 构建（守卫会拦截错误状态）
./build.sh web

# 2. 切到 gh-pages 分支并替换内容
git checkout gh-pages
rm -rf ./*       # 保留 .git
cp -R app/build/web/* .
git add -A && git commit -m "Deploy web" && git push

# 3. 回到 main
git checkout main
```

如需自定义 base href（例如部署到根域名）：`BASE_HREF=/ ./build.sh web`

## 技术栈

- Flutter + Dart
- Material 3
- Riverpod 状态管理
- GoRouter 导航
- Dio HTTP 客户端
- Flutter Secure Storage
- SQLite 本地存储
- DeepSeek API (用户自备密钥)
