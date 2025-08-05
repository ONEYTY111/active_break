# Active Break - 健身打卡应用

## 项目概述

Active Break 是一个使用 Flutter 开发的跨平台健身打卡应用，支持 iOS 和 Android 系统。应用采用 SQLite 数据库存储数据，提供完整的用户认证、运动记录、健康建议等功能。

## 主要功能

### 1. 用户认证系统
- 用户注册（支持手机号和邮箱）
- 用户登录
- 密码加密存储
- 个人资料管理

### 2. 四个主要页面

#### 首页
- 显示最近运动记录
- 周运动总结（总时长、总消耗卡路里）
- 运动趋势图表
- 连续打卡天数显示

#### 运动页面
- 运动类型列表（拉伸、慢跑、跳绳、步行、单车、椭圆机）
- 每种运动都有专属图标和颜色
- 运动计时器功能
- 提醒设置（频率、时间段）
- 运动记录保存

#### 推荐页面
- 每日健康建议展示
- 支持自动生成健康建议（可扩展 OpenAI 集成）
- 个性化建议内容

#### 我的页面
- 个人信息设置（头像、昵称、性别、年龄等）
- 主题切换（浅色/深色/跟随系统）
- 语言切换（中文/英文）
- 密码修改

### 3. 打卡功能
- 中间圆形打卡按钮
- 打卡成功提示
- 连续打卡天数统计
- 打卡记录存储

## 技术架构

### 前端技术栈
- **Flutter**: 跨平台 UI 框架
- **Provider**: 状态管理
- **Material Design 3**: UI 设计规范

### 数据存储
- **SQLite**: 本地数据库
- **SharedPreferences**: 用户偏好设置

### 主要依赖包
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  sqflite: ^2.3.0
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  http: ^1.1.0
  dio: ^5.4.0
  intl: ^0.20.2
  fl_chart: ^0.66.0
  image_picker: ^1.0.4
  cached_network_image: ^3.3.0
  crypto: ^3.0.3
  workmanager: ^0.5.2
  flutter_local_notifications: ^16.3.0
  permission_handler: ^11.1.0
  path_provider: ^2.1.1
```

## 数据库设计

### 主要数据表
1. **users**: 用户信息表
2. **t_check_in**: 打卡记录表
3. **t_user_checkin_streaks**: 用户打卡连续记录表
4. **t_physical_activities**: 运动类型表
5. **t_activi_record**: 运动记录表
6. **reminder_settings**: 提醒设置表
7. **user_tips**: 用户健康建议表

### 多语言支持
- **t_physical_activities_i18n**: 运动类型多语言表
- **health_tips_templates**: 健康建议模板表
- **user_settings**: 用户设置表

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── user.dart
│   ├── check_in.dart
│   ├── physical_activity.dart
│   └── reminder_and_tips.dart
├── providers/                # 状态管理
│   ├── user_provider.dart
│   ├── theme_provider.dart
│   ├── language_provider.dart
│   ├── activity_provider.dart
│   └── tips_provider.dart
├── screens/                  # 页面
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── main/
│       ├── main_screen.dart
│       ├── home_screen.dart
│       ├── exercise_screen.dart
│       ├── recommend_screen.dart
│       └── profile_screen.dart
├── widgets/                  # 自定义组件
│   ├── check_in_button.dart
│   ├── activity_chart.dart
│   ├── reminder_settings_dialog.dart
│   ├── edit_profile_dialog.dart
│   └── change_password_dialog.dart
├── services/                 # 服务层
│   └── database_service.dart
├── utils/                    # 工具类
│   ├── app_localizations.dart
│   └── activity_icons.dart
└── constants/                # 常量定义
```

## 运行说明

### 环境要求
- Flutter SDK 3.8.1+
- Dart SDK
- Android Studio / VS Code
- Chrome 浏览器（用于 Web 调试）

### 运行步骤
1. 克隆项目到本地
2. 进入项目目录：`cd active_break`
3. 安装依赖：`flutter pub get`
4. 运行应用：`flutter run`

### 支持平台
- ✅ Web (Chrome)
- ✅ macOS
- ✅ Android（需要 Android 模拟器或真机）
- ✅ iOS（需要 iOS 模拟器或真机，仅限 macOS）

## 功能特色

### 1. 国际化支持
- 中文/英文双语切换
- 完整的本地化文本
- 数据库多语言支持

### 2. 主题系统
- 浅色模式
- 深色模式
- 跟随系统设置

### 3. 运动管理
- 6种预设运动类型
- 自定义运动图标和颜色
- 实时计时功能
- 运动数据统计

### 4. 数据可视化
- 周运动趋势图表
- 运动数据统计
- 打卡连续天数展示

### 5. 智能提醒
- 自定义提醒频率
- 时间段设置
- 运动类型个性化提醒

## 扩展功能

### 1. OpenAI 集成（预留）
- 个性化健康建议生成
- 基于用户运动数据的智能推荐
- 自然语言处理

### 2. 定时任务（预留）
- 每日 12 点自动生成健康建议
- 后台运动提醒
- 数据同步

### 3. 社交功能（可扩展）
- 好友系统
- 运动挑战
- 成就系统

## 开发说明

### 代码规范
- 遵循 Flutter/Dart 官方代码规范
- 使用 Provider 进行状态管理
- 采用 Material Design 3 设计规范

### 测试
- 单元测试覆盖核心功能
- Widget 测试验证 UI 组件
- 集成测试确保功能完整性

### 部署
- 支持 Web 部署
- 支持 Android APK 打包
- 支持 iOS IPA 打包

## 许可证

本项目采用 MIT 许可证。

## 联系方式

如有问题或建议，请联系开发团队。
