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

# 清理构建产物
./build.sh clean
```

构建产物会输出到 `build/` 目录。

## 技术栈

- Flutter + Dart
- Material 3
- Riverpod 状态管理
- GoRouter 导航
- Dio HTTP 客户端
- Flutter Secure Storage
- SQLite 本地存储
- DeepSeek API (用户自备密钥)
