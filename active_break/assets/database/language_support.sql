-- 为支持多语言添加的数据库表修改语句

-- 1. 为用户表添加语言偏好字段
ALTER TABLE users ADD COLUMN preferred_language VARCHAR(10) DEFAULT 'zh';

-- 2. 为用户表添加主题偏好字段
ALTER TABLE users ADD COLUMN theme_preference VARCHAR(20) DEFAULT 'system';

-- 3. 创建多语言运动类型表
CREATE TABLE IF NOT EXISTS t_physical_activities_i18n (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    activity_type_id INTEGER NOT NULL,
    language_code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (activity_type_id) REFERENCES t_physical_activities(activity_type_id),
    UNIQUE(activity_type_id, language_code)
);

-- 4. 插入中文运动类型数据
INSERT OR REPLACE INTO t_physical_activities_i18n (activity_type_id, language_code, name, description) VALUES
(1, 'zh', '拉伸', '通过拉伸运动提高身体柔韧性，缓解肌肉紧张'),
(2, 'zh', '慢跑', '有氧运动，提高心肺功能，燃烧卡路里'),
(3, 'zh', '跳绳', '全身有氧运动，提高协调性和心肺功能'),
(4, 'zh', '步行', '低强度有氧运动，适合所有年龄段'),
(5, 'zh', '单车', '有氧运动，锻炼腿部肌肉，提高心肺功能'),
(6, 'zh', '椭圆机', '全身有氧运动，低冲击性，保护关节');

-- 5. 插入英文运动类型数据
INSERT OR REPLACE INTO t_physical_activities_i18n (activity_type_id, language_code, name, description) VALUES
(1, 'en', 'Stretching', 'Improve flexibility and relieve muscle tension through stretching exercises'),
(2, 'en', 'Jogging', 'Aerobic exercise to improve cardiovascular fitness and burn calories'),
(3, 'en', 'Jump Rope', 'Full-body aerobic exercise to improve coordination and cardiovascular fitness'),
(4, 'en', 'Walking', 'Low-intensity aerobic exercise suitable for all ages'),
(5, 'en', 'Cycling', 'Aerobic exercise to strengthen leg muscles and improve cardiovascular fitness'),
(6, 'en', 'Elliptical', 'Full-body aerobic exercise with low impact to protect joints');

-- 6. 创建多语言健康建议模板表
CREATE TABLE IF NOT EXISTS health_tips_templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    language_code VARCHAR(10) NOT NULL,
    category VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. 插入中文健康建议模板
INSERT INTO health_tips_templates (language_code, category, content) VALUES
('zh', 'hydration', '每天喝足够的水，保持身体水分平衡，建议每天至少8杯水。'),
('zh', 'exercise', '每天进行至少30分钟的中等强度运动，如快走、游泳或骑自行车。'),
('zh', 'sleep', '保证每晚7-9小时的优质睡眠，建立规律的作息时间。'),
('zh', 'nutrition', '均衡饮食，多吃蔬菜水果，减少加工食品的摄入。'),
('zh', 'stress', '学会管理压力，可以通过冥想、深呼吸或瑜伽来放松身心。'),
('zh', 'posture', '保持良好的坐姿和站姿，避免长时间保持同一姿势。'),
('zh', 'breaks', '工作时每小时起身活动5-10分钟，缓解肌肉紧张。'),
('zh', 'sunlight', '每天接受适量阳光照射，有助于维生素D的合成。'),
('zh', 'social', '保持良好的社交关系，与家人朋友多交流沟通。'),
('zh', 'mindfulness', '练习正念冥想，提高专注力和情绪管理能力。');

-- 8. 插入英文健康建议模板
INSERT INTO health_tips_templates (language_code, category, content) VALUES
('en', 'hydration', 'Drink enough water daily to maintain body hydration. Aim for at least 8 glasses per day.'),
('en', 'exercise', 'Engage in at least 30 minutes of moderate-intensity exercise daily, such as brisk walking, swimming, or cycling.'),
('en', 'sleep', 'Ensure 7-9 hours of quality sleep each night and establish a regular sleep schedule.'),
('en', 'nutrition', 'Maintain a balanced diet with plenty of vegetables and fruits while reducing processed food intake.'),
('en', 'stress', 'Learn to manage stress through meditation, deep breathing, or yoga to relax your mind and body.'),
('en', 'posture', 'Maintain good sitting and standing posture, avoiding staying in the same position for too long.'),
('en', 'breaks', 'Take 5-10 minute movement breaks every hour during work to relieve muscle tension.'),
('en', 'sunlight', 'Get adequate sunlight exposure daily to help with vitamin D synthesis.'),
('en', 'social', 'Maintain good social relationships and communicate regularly with family and friends.'),
('en', 'mindfulness', 'Practice mindfulness meditation to improve focus and emotional management skills.');

-- 9. 创建用户设置表
CREATE TABLE IF NOT EXISTS user_settings (
    user_id INTEGER PRIMARY KEY,
    language_preference VARCHAR(10) DEFAULT 'zh',
    theme_preference VARCHAR(20) DEFAULT 'system',
    notification_enabled BOOLEAN DEFAULT TRUE,
    reminder_sound BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- 10. 为现有用户创建默认设置
INSERT OR IGNORE INTO user_settings (user_id, language_preference, theme_preference)
SELECT user_id, 'zh', 'system' FROM users WHERE deleted = 0;
